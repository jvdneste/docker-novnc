FROM ubuntu:16.04

MAINTAINER Lucas Pantanella

ENV DEBIAN_FRONTEND noninteractive

RUN \
  apt-get update \
    && apt-get install -y \
# X Server
      xvfb \
# VNC Server
      x11vnc \
# Window manager
      i3 \
# NoVNC with dependencies
      git net-tools python-numpy \
  # must switch to a release tag once the ssl-only arg included
    && git clone https://github.com/novnc/noVNC /noVNC \
    && git clone --branch v0.8.0 https://github.com/novnc/websockify /noVNC/utils/websockify \
# Clean up the apt cache
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN \
  apt-get update \
    && apt-get install -y \
      vim byobu chromium-browser \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV SERVERNUM 1

CMD \
# X Server
  rm -f /tmp/.X1-lock \
    && setcap -r `which i3status` \
    && xvfb-run -f /root/.xvfbauth -n $SERVERNUM -s '-screen 0 1600x900x16' i3 & \
# VNC Server
  if [ -z $VNC_PASSWD ]; then \
    # no password
    x11vnc -auth /root/.xvfbauth -display :$SERVERNUM -xkb -forever & \
  else \
    # set password from VNC_PASSWD env variable
    mkdir -p ~/.x11vnc \
      && x11vnc -storepasswd $VNC_PASSWD /root/.x11vnc/passwd \
      && x11vnc -auth /root/.xvfbauth -display :$SERVERNUM -xkb -forever -rfbauth /root/.x11vnc/passwd & \
  fi \
# NoVNC
    && openssl req -new -x509 -days 36500 -nodes -batch -out /root/noVNC.pem -keyout /root/noVNC.pem \
    && ln -sf /noVNC/vnc.html /noVNC/index.html \
    && /noVNC/utils/launch.sh --vnc localhost:5900 --cert /root/noVNC.pem --ssl-only
