# AIMS — Shared Store (large files across machines)

> **Language:** English is the official language of AIMS. Translations live under
> [`docs/i18n/`](i18n/) — see [i18n/README.md](i18n/README.md).

Git is the source of truth for **pointers**; a shared network store holds the **bytes**. Files that
git should not track — build artifacts, dumps, images, tarballs, model weights, datasets — go to a
shared store that every machine mounts at **one logical path**, exactly like sessions live on one
`origin`.

This page explains the contract and gives copy-paste recipes for common backends:
**NFS, SMB/Samba, GlusterFS, CephFS, MinIO, RustFS, Ceph RGW (S3)**.

---

## 1. The contract

AIMS does not bundle a storage backend. It expects one environment variable pointing at a locally
mounted path:

```bash
export AIMS_ARTIFACTS="$HOME/.aims-artifacts"   # local mount point of the shared store
# then, per session:  aims artifacts <session-id>   # -> $AIMS_ARTIFACTS/<session-id>/  (created on demand)
```

- **One logical path on every machine.** Sessions and agents reference `$AIMS_ARTIFACTS/<session-id>/`,
  never a backend-specific path like `/mnt/store` or `s3://bucket`. Each machine maps that logical path
  to wherever the store is mounted locally. This is the same portability principle as branches on `origin`.
- **Git keeps a manifest, not the blob.** Next to a session, commit a small pointer: logical path,
  size, `sha256`, source session. Git remains the record of *what exists*; the store holds the *content*.
- **Write discipline.** Only the owning session writes its `<session-id>/` directory. Treat published
  artifacts as immutable.
- **No secrets on the shared store.** A shared, network-reachable store is not a secret vault. Keep
  secrets where [`SECURITY.md`](../SECURITY.md) says (OS keychain, vault, CI secrets).

## 2. Two families of backend

| Family | Backends | Appears as | Notes |
|---|---|---|---|
| **POSIX file mounts** | NFS, SMB/Samba, GlusterFS, CephFS | a real directory | simplest; mount → use the path directly |
| **Object stores (S3)** | MinIO, RustFS, Ceph RGW | a bucket | need a FUSE bridge (`rclone mount` / `s3fs`) to appear as a path, or use the S3 API directly |

Pick a POSIX mount if you want the store to *be* `$AIMS_ARTIFACTS` with no extra layer. Pick an object
store if you already run one, want HTTP access, versioning, or scale-out — and bridge it to a path.

Replace every `storage.example.internal`, `10.0.0.10`, `USER`, `PASSWORD`, and `bucket` below with
your own values.

---

## 3. POSIX file-mount backends

### 3.1 NFS

**Server** (`/etc/exports`, then `exportfs -ra`):
```
/srv/aims-artifacts  10.0.0.0/24(rw,sync,no_subtree_check,root_squash)
```

**Linux client** (`/etc/fstab`):
```
storage.example.internal:/srv/aims-artifacts  /mnt/aims  nfs  _netdev,noatime  0 0
```
```bash
sudo mkdir -p /mnt/aims && sudo mount /mnt/aims
export AIMS_ARTIFACTS=/mnt/aims
```

**macOS client** (no root needed for a user mount):
```bash
mkdir -p ~/.aims-artifacts
mount -t nfs -o resvport,rw storage.example.internal:/srv/aims-artifacts ~/.aims-artifacts
export AIMS_ARTIFACTS=~/.aims-artifacts
```

### 3.2 SMB / Samba

**Server** (`/etc/samba/smb.conf`):
```ini
[aims-artifacts]
   path = /srv/aims-artifacts
   read only = no
   browseable = yes
   valid users = USER
   veto files = /._*/.DS_Store/.Trashes/.TemporaryItems/.fseventsd/.Spotlight-V100/
   delete veto files = yes
```
```bash
sudo smbpasswd -a USER && sudo systemctl restart smbd
```

**Linux client** (`/etc/fstab`, credentials in a root-only file):
```
//storage.example.internal/aims-artifacts  /mnt/aims  cifs  _netdev,credentials=/etc/aims-smb.cred,uid=1000,gid=1000  0 0
```

**macOS client** (native SMB):
```bash
mkdir -p ~/.aims-artifacts
mount_smbfs //USER@storage.example.internal/aims-artifacts ~/.aims-artifacts
export AIMS_ARTIFACTS=~/.aims-artifacts
```
Persist across login on macOS with a per-user LaunchAgent that runs the `mount_smbfs` line at
`RunAtLoad` with a retry loop (network may not be up at login). This avoids `sudo` and survives reboot.

### 3.3 GlusterFS

Native FUSE mount (Linux clients with the gluster client installed):
```bash
sudo mount -t glusterfs storage.example.internal:/aims /mnt/aims
export AIMS_ARTIFACTS=/mnt/aims
```
`/etc/fstab`:
```
storage.example.internal:/aims  /mnt/aims  glusterfs  _netdev,backup-volfile-servers=storage2.example.internal  0 0
```

**Clients without a gluster client (e.g. macOS): export the volume over SMB.** Run Samba on a gluster
server with the native `vfs_glusterfs` module, then mount via SMB (§3.2):
```ini
[aims-artifacts]
   vfs objects = glusterfs
   glusterfs:volume = aims
   path = /
   read only = no
   kernel share modes = no
```
For high availability, front the SMB export with CTDB and mount clients at the floating VIP, so a node
failover does not drop the client.

> **Boot ordering caveat (learned the hard way).** If your storage network rides an overlay (ZeroTier,
> Tailscale, WireGuard), `network-online.target` does **not** wait for it, and `glusterd`/`ctdb` may
> start before the overlay has an IP or before bricks bind their ports. Gate the mount and services on
> the overlay actually having the node IP, and give the mount a generous retry budget. Verify reboot
> survival with a real reboot, not a simulation.

### 3.4 CephFS

```bash
sudo mount -t ceph USER@<fsid>.aims=/ /mnt/aims -o mon_addr=storage.example.internal
export AIMS_ARTIFACTS=/mnt/aims
```
Or with the kernel client and a secret file:
```
storage.example.internal:/  /mnt/aims  ceph  name=USER,secretfile=/etc/ceph/aims.secret,_netdev  0 2
```

---

## 4. Object-store backends (S3) + FUSE bridge

Object stores expose an S3 API, not a POSIX path. Bridge them to `$AIMS_ARTIFACTS` with **rclone
mount** (recommended) or **s3fs**. Credentials go in the tool's config, never in git.

### 4.1 rclone bridge (works for MinIO, RustFS, Ceph RGW)

```bash
rclone config create aims s3 \
  provider=Other \
  endpoint=https://storage.example.internal:9000 \
  access_key_id=ACCESS_KEY secret_access_key=SECRET_KEY
mkdir -p ~/.aims-artifacts
rclone mount aims:aims-artifacts ~/.aims-artifacts \
  --vfs-cache-mode writes --daemon
export AIMS_ARTIFACTS=~/.aims-artifacts
```

### 4.2 MinIO

Server (single node, for a team store):
```bash
docker run -d --name minio -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=USER -e MINIO_ROOT_PASSWORD=PASSWORD \
  -v /srv/minio:/data minio/minio server /data --console-address ":9001"
```
Create the bucket and a scoped key:
```bash
mc alias set store https://storage.example.internal:9000 USER PASSWORD
mc mb store/aims-artifacts
mc admin user svcacct add store USER      # use the returned key pair in the rclone bridge (§4.1)
```

### 4.3 RustFS

RustFS is an S3-compatible object store (drop-in alternative to MinIO). Run it, create the bucket, then
use the **same** `mc` and **rclone** steps as MinIO — only the endpoint/keys differ:
```bash
docker run -d --name rustfs -p 9000:9000 \
  -e RUSTFS_ACCESS_KEY=USER -e RUSTFS_SECRET_KEY=PASSWORD \
  -v /srv/rustfs:/data rustfs/rustfs
mc alias set store https://storage.example.internal:9000 USER PASSWORD
mc mb store/aims-artifacts
```
Then bridge with rclone (§4.1). Because it speaks S3, any S3 client/tooling works unchanged.

### 4.4 Ceph RGW (S3 gateway)

If you already run Ceph, expose artifacts through the RADOS Gateway instead of CephFS:
```bash
radosgw-admin user create --uid=aims --display-name="AIMS"
# use the returned access_key/secret_key with rclone (§4.1), endpoint = your RGW URL
mc alias set store https://rgw.example.internal USER PASSWORD && mc mb store/aims-artifacts
```

---

## 5. Choosing a backend

| Backend | Best when | Trade-off |
|---|---|---|
| **NFS** | all-Linux, simplest possible | weak cross-OS; no built-in HA |
| **SMB/Samba** | mixed macOS/Windows/Linux | ACLs fiddly; add CTDB for HA |
| **GlusterFS** | replicated POSIX, self-hosted HA | needs SMB gateway for non-Linux clients |
| **CephFS** | large clusters, POSIX at scale | operational weight |
| **MinIO / RustFS** | S3 API, HTTP access, simple to run | needs FUSE bridge for a path |
| **Ceph RGW** | already running Ceph | heaviest to operate |

A small team on mixed OS: **SMB (optionally Gluster+CTDB behind it)**. An all-Linux setup: **NFS**.
Already have object storage or want HTTP/versioning: **MinIO/RustFS via rclone**.

## 6. Security posture

- The shared store is reachable by everyone on its network. **No secrets, ever.**
- Prefer per-user/scoped credentials (SMB users, S3 service accounts) over a single shared root key.
- Object-store keys live in `rclone`/`s3fs` config with `0600` perms, outside git.
- Restrict exports to the trusted subnet/overlay; do not expose to the public internet.

## 7. Verify it works (any backend)

Prove the store is genuinely shared — write on one machine, read on another:
```bash
# machine A
echo "hello $(date -u +%FT%TZ)" > "$AIMS_ARTIFACTS/.probe"
# machine B
cat "$AIMS_ARTIFACTS/.probe"      # must show A's line
rm -f "$AIMS_ARTIFACTS/.probe"
```
If A's write is visible on B through the same logical path, the contract holds.
