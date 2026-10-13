#!/bin/sh
# Install every screensaver's .deb the way a user would, then run each program without
# a screen and keep the picture it draws. Run as root on Debian or Ubuntu, with the
# .deb files in ./debs. Exits non-zero if any of them fails.
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null 2>&1
mkdir -p out
bad=0
for deb in debs/*.deb; do
    name=$(dpkg-deb -f "$deb" Package); version=$(dpkg-deb -f "$deb" Version)
    if ! apt-get install -y -qq "./$deb" >/tmp/apt.log 2>&1; then
        echo "FAIL  $name $version: does not install: $(grep -m3 -i 'depends\|unmet\|^E:' /tmp/apt.log | tr '\n' ' ')"; bad=1; continue
    fi
    if SDL_VIDEODRIVER=dummy "$name" --snapshot "out/$name.bmp" --time 5 --size 640x360 >/tmp/run.log 2>&1 && [ -s "out/$name.bmp" ]; then
        notes=""
        "/usr/bin/$name-screensaver" status >/dev/null 2>&1 || notes="$notes; its -screensaver command fails"
        [ -f "/usr/share/applications/$name.desktop" ] || notes="$notes; no menu entry"
        echo "ok    $name $version: installs and draws$notes"
    else
        echo "FAIL  $name $version: installs but does not run: $(head -3 /tmp/run.log | tr '\n' ' ')"; bad=1
    fi
done
exit $bad
