#!/bin/bash

mkdir -p /srv/tftpboot /srv/nfsroot
chown -R nobody:nogroup /srv/tftpboot /srv/nfsroot || true

# export NFS share (allow any host; restrict as needed)
if ! grep -q '^/srv/nfsroot ' /etc/exports 2>/dev/null; then
  echo "/srv/nfsroot *(rw,no_root_squash,no_subtree_check,async)" >> /etc/exports
fi

# Start RPC bind
echo "starting rpcbind..."
/sbin/rpcbind -w

# start rpc.statd if available (some distros package it under /sbin)
if command -v rpc.statd >/dev/null 2>&1; then
  rpc.statd --no-notify &
fi

# start mountd on a fixed port so it can be exposed
echo "starting rpc.mountd on port 20048..."
/sbin/rpc.mountd --port 20048 &

# start nfsd (spawn a few threads)
echo "starting rpc.nfsd..."
/sbin/rpc.nfsd 8

# export configured shares
exportfs -rav || true

# start TFTP server (in.tftpd runs foreground with -L; fall back to background if needed)
echo "starting tftp server..."
/usr/sbin/in.tftpd -L -v -s /srv/tftpboot -p 69 &

# wait on background processes (keep container running)
wait -n
