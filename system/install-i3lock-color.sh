#!/usr/bin/env bash
# Build and install i3lock-color (i3lock with a clock and a themable ring) into /usr/local.
# Ubuntu doesn't package it. /usr/local/bin/i3lock takes precedence over the apt i3lock,
# which stays installed as a fallback.
set -euo pipefail
# build with the system toolchain only: Homebrew's pkg-config (if on PATH) can't see the apt -dev packages
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
unset PKG_CONFIG_PATH PKG_CONFIG_LIBDIR CPATH LIBRARY_PATH LDFLAGS CPPFLAGS
VER=2.13.c.5
sudo apt-get update -qq
sudo apt-get install -y autoconf gcc make pkg-config git libpam0g-dev libcairo2-dev libfontconfig1-dev \
  libxcb-composite0-dev libev-dev libx11-xcb-dev libxcb-xkb-dev libxcb-xinerama0-dev libxcb-randr0-dev \
  libxcb-image0-dev libxcb-util0-dev libxcb-xrm-dev libxkbcommon-dev libxkbcommon-x11-dev libjpeg-dev libgif-dev
SRC=$(mktemp -d)
trap 'rm -rf "$SRC"' EXIT
git clone -q --depth 1 --branch "$VER" https://github.com/Raymo111/i3lock-color.git "$SRC"
cd "$SRC"
autoreconf -fi
mkdir build && cd build
../configure --prefix=/usr/local --sysconfdir=/etc --disable-sanitizers
make -j"$(nproc)"
sudo make install
hash -r
echo "installed: $(/usr/local/bin/i3lock --version 2>&1 | head -1)"
