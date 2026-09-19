FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kolkata

RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4-session \
    xfce4-panel \
    xfdesktop4 \
    xfwm4 \
    thunar \
    xfce4-terminal \
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
    psmisc \
    htop \
    bash-completion \
    openssh-server \
    xauth \
    x11-xserver-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    /var/cache/apt/* \
    /tmp/*

# RDP user
RUN useradd -m -s /bin/bash rdpuser \
    && usermod -aG sudo rdpuser \
    && echo "rdpuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/rdpuser \
    && chmod 440 /etc/sudoers.d/rdpuser

# XRDP session
RUN printf '%s\n' \
    '#!/bin/sh' \
    'unset DBUS_SESSION_BUS_ADDRESS' \
    'unset XDG_RUNTIME_DIR' \
    'export XDG_CURRENT_DESKTOP=XFCE' \
    'export XDG_SESSION_DESKTOP=xfce' \
    'exec dbus-run-session startxfce4' \
    > /etc/xrdp/startwm.sh \
    && chmod +x /etc/xrdp/startwm.sh

# SSH
RUN mkdir -p /run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Persistent data directory
RUN mkdir -p /data \
    && chown rdpuser:rdpuser /data

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389
EXPOSE 22

CMD ["/start.sh"]