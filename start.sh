#!/bin/bash

set -e

echo "======================================"
echo " Railway Lightweight Ubuntu RDP"
echo "======================================"

RDP_USER="${RDP_USER:-rdpuser}"
RDP_PASSWORD="${RDP_PASSWORD:-}"

if [ -z "$RDP_PASSWORD" ]; then
    echo "ERROR: RDP_PASSWORD is not configured."
    exit 1
fi

echo "RDP user: $RDP_USER"

# Create user if necessary
if ! id "$RDP_USER" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "$RDP_USER"
    usermod -aG sudo "$RDP_USER"

    echo "$RDP_USER ALL=(ALL) NOPASSWD:ALL" \
        > "/etc/sudoers.d/$RDP_USER"

    chmod 440 "/etc/sudoers.d/$RDP_USER"
fi

echo "$RDP_USER:$RDP_PASSWORD" | chpasswd

USER_HOME=$(getent passwd "$RDP_USER" | cut -d: -f6)

mkdir -p "$USER_HOME"

# XFCE session
cat > "$USER_HOME/.xsession" <<'EOF'
#!/bin/sh

unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce

exec dbus-run-session startxfce4
EOF

chown "$RDP_USER:$RDP_USER" "$USER_HOME/.xsession"
chmod +x "$USER_HOME/.xsession"

# Persistent directories
mkdir -p /data
chown "$RDP_USER:$RDP_USER" /data

for DIR in Desktop Downloads Documents Pictures Videos
do
    mkdir -p "/data/$DIR"
    chown "$RDP_USER:$RDP_USER" "/data/$DIR"

    if [ ! -e "$USER_HOME/$DIR" ]; then
        ln -s "/data/$DIR" "$USER_HOME/$DIR"
    fi
done

# Runtime directories
mkdir -p /run/dbus
mkdir -p /var/run/xrdp
mkdir -p /var/run/xrdp-sesman

chown xrdp:xrdp /var/run/xrdp 2>/dev/null || true
chown xrdp:xrdp /var/run/xrdp-sesman 2>/dev/null || true

# DBus
echo "Starting DBus..."

dbus-daemon --system --fork 2>/dev/null || true

# SSH
echo "Starting SSH..."

/usr/sbin/sshd

# XRDP session manager
echo "Starting XRDP session manager..."

/usr/sbin/xrdp-sesman --nodaemon &

sleep 2

# XRDP
echo "Starting XRDP..."

/usr/sbin/xrdp --nodaemon &

XRDP_PID=$!

sleep 3

echo ""
echo "======================================"
echo " XRDP READY"
echo " Port: 3389"
echo " User: $RDP_USER"
echo "======================================"

if ss -lntp | grep -q ":3389"; then
    echo "SUCCESS: XRDP listening on 3389"
else
    echo "WARNING: XRDP port 3389 not detected"
fi

echo ""

wait "$XRDP_PID"