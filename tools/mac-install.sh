#!/bin/sh
# Install the Anathem screensavers on a Mac.
#
#   all of them:
#     curl -fsSL https://raw.githubusercontent.com/mottipython/anathem-screensavers/main/tools/mac-install.sh | sh
#   only some:
#     curl -fsSL https://raw.githubusercontent.com/mottipython/anathem-screensavers/main/tools/mac-install.sh | sh -s -- edhar-clock wick
#   take them off again (all, or the ones named):
#     curl -fsSL https://raw.githubusercontent.com/mottipython/anathem-screensavers/main/tools/mac-install.sh | sh -s -- --uninstall
#
# Each screen saver module goes into ~/Library/Screen Savers, for your user only, so no
# password is asked for. Then choose one in System Settings, Screen Saver.
ALL="teglon lazy-peregrin cutting-the-cake edhar-clock weed-war daban-urnud adrakhonic analemma bolt-chord-sphere wick fraa-in-orbit fly-bat-worm page-trees hemn-space"
title() {
    case "$1" in
    teglon) echo "Teglon" ;; lazy-peregrin) echo "The Lazy Peregrin" ;; cutting-the-cake) echo "Cutting the Cake" ;;
    edhar-clock) echo "The Clock of Saunt Edhar" ;; weed-war) echo "The Weed War" ;; daban-urnud) echo "The Daban Urnud" ;;
    adrakhonic) echo "The Adrakhonic Theorem" ;; analemma) echo "The Analemma" ;; bolt-chord-sphere) echo "Bolt, Chord and Sphere" ;;
    wick) echo "The Wick" ;; fraa-in-orbit) echo "A Fraa in Orbit" ;; fly-bat-worm) echo "Fly, Bat, Worm" ;; page-trees) echo "The Page Trees" ;;
    hemn-space) echo "Hemn Space" ;;
    *) return 1 ;;
    esac
}
[ "$(uname -s)" = Darwin ] || { echo "This is for macOS."; exit 1; }
uninstall=0; chosen=""
for a in "$@"; do
    case "$a" in
    --uninstall) uninstall=1 ;;
    -h|--help) sed -n '2,12p' "$0" 2>/dev/null; echo "Names: $ALL"; exit 0 ;;
    *) title "$a" >/dev/null || { echo "No screensaver called $a. Names: $ALL"; exit 1; }; chosen="$chosen $a" ;;
    esac
done
[ -n "$chosen" ] || chosen=$ALL
dest="$HOME/Library/Screen Savers"; mkdir -p "$dest"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
bad=0
for name in $chosen; do
    t=$(title "$name")
    if [ $uninstall = 1 ]; then
        if [ -d "$dest/$t.saver" ]; then rm -rf "$dest/$t.saver"; echo "removed    $t"; fi
        continue
    fi
    url=$(curl -fsSL "https://api.github.com/repos/mottipython/$name/releases/latest" | grep browser_download_url | grep -- '-mac-screensaver.zip' | sed 's/.*"\(https[^"]*\)".*/\1/' | head -1)
    if [ -z "$url" ] || ! curl -fsSL -o "$tmp/$name.zip" "$url"; then echo "FAILED     $t: could not download it"; bad=1; continue; fi
    rm -rf "$tmp/x"; mkdir "$tmp/x"
    if ! ditto -x -k "$tmp/$name.zip" "$tmp/x" || [ ! -d "$tmp/x/$t.saver" ]; then echo "FAILED     $t: the download was not what was expected"; bad=1; continue; fi
    rm -rf "$dest/$t.saver"; cp -R "$tmp/x/$t.saver" "$dest/"
    xattr -dr com.apple.quarantine "$dest/$t.saver" 2>/dev/null
    echo "installed  $t"
done
if [ $uninstall = 1 ]; then echo "Done."; exit 0; fi
echo
echo "They are in System Settings, Screen Saver, at the end of the list. Opening it now."
open "x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension" 2>/dev/null || open "/System/Library/PreferencePanes/DesktopScreenEffectsPref.prefPane" 2>/dev/null
exit $bad
