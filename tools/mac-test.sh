#!/bin/sh
# Try every Anathem screensaver on this Mac, one after another, and say what happened.
#   curl -fsSL https://raw.githubusercontent.com/mottipython/anathem-screensavers/main/tools/mac-test.sh | sh
# It downloads each one's Mac app and screen saver module, installs the modules for
# this user, shows each app in a window for a few seconds, and writes a report.
dir="$HOME/anathem-mac-test"; report="$dir/report.txt"
mkdir -p "$dir" "$HOME/Library/Screen Savers"; cd "$dir" || exit 1
: > "$report"
say() { echo "$*" | tee -a "$report"; }
say "Mac: $(sw_vers -productName 2>/dev/null) $(sw_vers -productVersion 2>/dev/null), $(uname -m)"
say ""
for repo in edhar-clock teglon lazy-peregrin cutting-the-cake weed-war daban-urnud adrakhonic analemma bolt-chord-sphere wick fraa-in-orbit fly-bat-worm page-trees; do
    urls=$(curl -fsSL "https://api.github.com/repos/mottipython/$repo/releases/latest" | grep browser_download_url | grep -- '-mac' | sed 's/.*"\(https[^"]*\)".*/\1/')
    [ -n "$urls" ] || { say "FAIL  $repo: no Mac downloads found"; continue; }
    rm -rf "$repo"; mkdir "$repo"
    for u in $urls; do curl -fsSL -o "$repo/$(basename "$u")" "$u" && ditto -x -k "$repo/$(basename "$u")" "$repo"; done
    xattr -dr com.apple.quarantine "$repo" 2>/dev/null
    line=""; bad=0
    # the screen saver module: install it for this user
    saver=$(ls -d "$repo"/*.saver 2>/dev/null | head -1)
    if [ -n "$saver" ]; then
        rm -rf "$HOME/Library/Screen Savers/$(basename "$saver")"; cp -R "$saver" "$HOME/Library/Screen Savers/"
        if codesign --verify "$saver" 2>/dev/null; then line="module installed"; else line="module installed but its signature does not verify"; bad=1; fi
    else line="no module"; bad=1; fi
    # the app: draw one frame without a window, then show it in a window for a few seconds
    app=$(ls -d "$repo"/*.app 2>/dev/null | head -1); bin="$app/Contents/MacOS/$repo"
    if [ -x "$bin" ]; then
        if SDL_VIDEODRIVER=dummy "$bin" --snapshot "$repo/frame.bmp" --time 5 --size 640x360 >"$repo/log.txt" 2>&1 && [ -s "$repo/frame.bmp" ]; then line="$line; app draws"; else line="$line; app does not draw ($(head -1 "$repo/log.txt"))"; bad=1; fi
        "$bin" --window >"$repo/window.txt" 2>&1 &
        pid=$!; sleep 7
        if kill -0 $pid 2>/dev/null; then
            screencapture -x "$repo/screen.png" 2>/dev/null
            kill $pid 2>/dev/null; wait $pid 2>/dev/null
            line="$line; window stayed open 7 s"
        else
            wait $pid; line="$line; window closed early, exit $? ($(head -1 "$repo/window.txt"))"; bad=1
        fi
    else line="$line; no app"; bad=1; fi
    if [ $bad = 0 ]; then say "ok    $repo: $line"; else say "FAIL  $repo: $line"; fi
done
say ""
say "Screen saver modules are in ~/Library/Screen Savers. Opening the Screen Saver settings:"
say "look for them at the end of the list, pick one, and see whether its preview moves."
open "x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension" 2>/dev/null || open "/System/Library/PreferencePanes/DesktopScreenEffectsPref.prefPane" 2>/dev/null
echo; echo "The report is in $report"
