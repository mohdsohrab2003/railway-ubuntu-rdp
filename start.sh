#!/bin/bash

set -e

echo "======================================"
echo " Railway Ubuntu RDP Starting"
echo "======================================"

# --------------------------------------------------
# Environment variables
# --------------------------------------------------

RDP_USER="${RDP_USER:-rdpuser}"
RDP_PASSWORD="${RDP_PASSWORD:-}"

if [ -z "$RDP_PASSWORD" ]; then
    echo "ERROR: RDP_PASSWORD is not configured."
    exit 1
fi

echo "RDP user: $RDP_USER"

# --------------------------------------------------
# Create user if it does not exist
# --------------------------------------------------

if ! id "$RDP_USER" >/dev/null 2>&1; then
    echo "Creating user $RDP_USER..."

    useradd \
        -m \
        -s /bin/bash \
        "$RDP_USER"

    usermod -aG sudo "$RDP_USER"

    echo "$RDP_USER ALL=(ALL) NOPASSWD:ALL" \
        > "/etc/sudoers.d/$RDP_USER"

    chmod 440 "/etc/sudoers.d/$RDP_USER"
fi

# --------------------------------------------------
# Set password
# --------------------------------------------------

echo "$RDP_USER:$RDP_PASSWORD" | chpasswd

# --------------------------------------------------
# Prepare XFCE session
# --------------------------------------------------

USER_HOME=$(getent passwd "$RDP_USER" | cut -d: -f6)

mkdir -p "$USER_HOME"

cat > "$USER_HOME/.xsession" <<EOF
#!/bin/sh
exec dbus-run-session startxfce4
EOF

chown "$RDP_USER:$RDP_USER" "$USER_HOME/.xsession"
chmod +x "$USER_HOME/.xsession"

# --------------------------------------------------
# Create persistent directories
# --------------------------------------------------

mkdir -p /data

chown "$RDP_USER:$RDP_USER" /data

mkdir -p /data/Desktop
mkdir -p /data/Downloads
mkdir -p /data/Documents
mkdir -p /data/Pictures
mkdir -p /data/Videos

chown -R "$RDP_USER:$RDP_USER" /data

# --------------------------------------------------
# Link persistent folders
# --------------------------------------------------

for DIR in Desktop Downloads Documents Pictures Videos
do
    if [ ! -L "$USER_HOME/$DIR" ]; then

        if [ -d "$USER_HOME/$DIR" ]; then
            cp -a "$USER_HOME/$DIR/." "/data/$DIR/" 2>/dev/null || true
            rm -rf "$USER_HOME/$DIR"
        fi

        ln -s "/data/$DIR" "$USER_HOME/$DIR"
    fi
done

chown -h "$RDP_USER:$RDP_USER" \
    "$USER_HOME/Desktop" \
    "$USER_HOME/Downloads" \
    "$USER_HOME/Documents" \
    "$USER_HOME/Pictures" \
    "$USER_HOME/Videos" \
    2>/dev/null || true

# --------------------------------------------------
# Runtime directories
# --------------------------------------------------

mkdir -p /run/dbus
mkdir -p /var/run/xrdp
mkdir -p /var/run/xrdp-sesman

chown xrdp:xrdp /var/run/xrdp 2>/dev/null || true
chown xrdp:xrdp /var/run/xrdp-sesman 2>/dev/null || true

# --------------------------------------------------
# Start DBus
# --------------------------------------------------

echo "Starting DBus..."

if command -v dbus-daemon >/dev/null 2>&1; then
    dbus-daemon --system --fork || true
fi

# --------------------------------------------------
# Start SSH
# --------------------------------------------------

echo "Starting SSH..."

/usr/sbin/sshd

# --------------------------------------------------
# Start XRDP session manager
# --------------------------------------------------

echo "Starting XRDP session manager..."

/usr/sbin/xrdp-sesman --nodaemon &
XRDP_SESMAN_PID=$!

sleep 2

# --------------------------------------------------
# Start XRDP
# --------------------------------------------------

echo "Starting XRDP..."

/usr/sbin/xrdp --nodaemon &
XRDP_PID=$!

sleep 3

# --------------------------------------------------
# Verify
# --------------------------------------------------

echo ""
echo "======================================"
echo " XRDP is running"
echo " Port: 3389"
echo " User: $RDP_USER"
echo "======================================"
echo ""

if ss -lntp | grep -q ":3389"; then
    echo "SUCCESS: XRDP listening on port 3389"
else
    echo "WARNING: XRDP port 3389 not detected"
fi

echo ""

# --------------------------------------------------
# Keep container alive
# --------------------------------------------------

wait $XRDP_PID