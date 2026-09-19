FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kolkata

# ---------------------------------------
# Minimal XFCE + XRDP + basic utilities
# ---------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4-session \
    xfce4-panel \
    xfdesktop4 \
    xfwm4 \
    thunar \
    thunar-archive-plugin \
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

# ---------------------------------------
# RDP user
# ---------------------------------------
RUN useradd -m -s /bin/bash rdpuser \
    && usermod -aG sudo rdpuser \
    && echo "rdpuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/rdpuser \
    && chmod 440 /etc/sudoers.d/rdpuser

# ---------------------------------------
# XRDP configuration
# ---------------------------------------
RUN sed -i 's/^port=3389/port=3389/' /etc/xrdp/xrdp.ini

RUN printf '%s\n' \
    '#!/bin/sh' \
    'unset DBUS_SESSION_BUS_ADDRESS' \
    'unset XDG_RUNTIME_DIR' \
    'export XDG_CURRENT_DESKTOP=XFCE' \
    'export XDG_SESSION_DESKTOP=xfce' \
    'export XDG_CONFIG_DIRS=/etc/xdg/xdg-xfce:/etc/xdg' \
    'export XDG_DATA_DIRS=/usr/share/xfce4:/usr/local/share:/usr/share' \
    'exec dbus-run-session startxfce4' \
    > /etc/xrdp/startwm.sh \
    && chmod +x /etc/xrdp/startwm.sh

# ---------------------------------------
# SSH
# ---------------------------------------
RUN mkdir -p /run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# ---------------------------------------
# Persistent directories
# ---------------------------------------
RUN mkdir -p /data \
    && chown rdpuser:rdpuser /data

# ---------------------------------------
# Firefox
# ---------------------------------------
RUN cd /tmp \
    && wget -q -O firefox.tar.xz \
       "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US" \
    && tar -xJf firefox.tar.xz -C /opt/ \
    && ln -sf /opt/firefox/firefox /usr/local/bin/firefox \
    && rm -f /tmp/firefox.tar.xz

# ---------------------------------------
# Firefox lightweight profile
# ---------------------------------------
RUN mkdir -p /home/rdpuser/.mozilla/firefox/railway \
    && printf '%s\n' \
       'user_pref("browser.startup.page", 1);' \
       'user_pref("browser.startup.homepage", "about:blank");' \
       'user_pref("browser.sessionstore.resume_from_crash", false);' \
       'user_pref("browser.cache.disk.enable", false);' \
       'user_pref("browser.cache.memory.enable", true);' \
       'user_pref("browser.cache.memory.capacity", 65536);' \
       'user_pref("browser.tabs.unloadOnLowMemory", true);' \
       > /home/rdpuser/.mozilla/firefox/railway/user.js \
    && chown -R rdpuser:rdpuser /home/rdpuser/.mozilla

# ---------------------------------------
# Startup script
# ---------------------------------------
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389
EXPOSE 22

CMD ["/start.sh"]