FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kolkata

# --------------------------------------------------
# Install desktop + XRDP + useful tools
# --------------------------------------------------
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xrdp \
    xorgxrdp \
    dbus \
    dbus-x11 \
    sudo \
    curl \
    wget \
    git \
    nano \
    vim \
    unzip \
    zip \
    ca-certificates \
    net-tools \
    iproute2 \
    procps \
    htop \
    bash-completion \
    openssh-server \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# Create user
# --------------------------------------------------
RUN useradd -m -s /bin/bash rdpuser \
    && usermod -aG sudo rdpuser \
    && echo "rdpuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/rdpuser \
    && chmod 440 /etc/sudoers.d/rdpuser

# --------------------------------------------------
# XRDP configuration
# --------------------------------------------------
RUN sed -i 's/^port=3389/port=3389/' /etc/xrdp/xrdp.ini

# Make XRDP use XFCE
RUN printf '%s\n' \
    '#!/bin/sh' \
    'unset DBUS_SESSION_BUS_ADDRESS' \
    'unset XDG_RUNTIME_DIR' \
    'exec dbus-run-session startxfce4' \
    > /etc/xrdp/startwm.sh \
    && chmod +x /etc/xrdp/startwm.sh

# --------------------------------------------------
# SSH configuration
# Optional - useful for terminal access
# --------------------------------------------------
RUN mkdir -p /run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# --------------------------------------------------
# Persistent data directory
# --------------------------------------------------
RUN mkdir -p /data \
    && chown rdpuser:rdpuser /data

# --------------------------------------------------
# Startup script
# --------------------------------------------------
COPY start.sh /start.sh
RUN chmod +x /start.sh

# XRDP
EXPOSE 3389

# SSH
EXPOSE 22

CMD ["/start.sh"]