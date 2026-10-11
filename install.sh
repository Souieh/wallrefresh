#!/usr/bin/env bash
# Installs wallrefresh for the current user.
#   ./install.sh [--no-timer] [--no-widget] [--login-screen]
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

WITH_TIMER=1; WITH_WIDGET=1; WITH_LOGIN=0
for a in "$@"; do
  case $a in
    --no-timer)     WITH_TIMER=0 ;;
    --no-widget)    WITH_WIDGET=0 ;;
    --login-screen) WITH_LOGIN=1 ;;
    -h|--help)
      sed -n '2,3p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $a" >&2; exit 1 ;;
  esac
done

# --- dependencies -----------------------------------------------------------
missing=0
for c in curl jq shuf flock kwriteconfig6 plasma-apply-wallpaperimage; do
  command -v "$c" >/dev/null || { echo "Missing dependency: $c" >&2; missing=1; }
done
[ "$missing" = 0 ] || { echo "Install the missing tools first (e.g. sudo pacman -S curl jq util-linux)" >&2; exit 1; }

# --- wallpaper directory ----------------------------------------------------
CONF="$HOME/.config/wallrefresh.conf"
DIR=$( [ -r "$CONF" ] && . "$CONF"; echo "${WALLPAPER_DIR:-/usr/local/share/wallpapers}" )
if [ ! -w "$DIR" ]; then
  echo "Creating $DIR (needs sudo)"
  sudo mkdir -p "$DIR"
  sudo chown "$USER": "$DIR"
  sudo chmod 755 "$DIR"
fi

# --- script and config ------------------------------------------------------
install -Dm755 bin/wallrefresh "$HOME/.local/bin/wallrefresh"
if [ ! -e "$CONF" ]; then
  install -Dm600 config/wallrefresh.conf.example "$CONF"
  echo "Created $CONF - add your API keys there."
else
  echo "Keeping existing $CONF"
fi

# --- systemd timer ----------------------------------------------------------
if [ "$WITH_TIMER" = 1 ]; then
  install -Dm644 systemd/wallrefresh.service "$HOME/.config/systemd/user/wallrefresh.service"
  install -Dm644 systemd/wallrefresh.timer   "$HOME/.config/systemd/user/wallrefresh.timer"
  systemctl --user daemon-reload
  systemctl --user enable --now wallrefresh.timer
fi

# --- panel widget -----------------------------------------------------------
if [ "$WITH_WIDGET" = 1 ]; then
  dest="$HOME/.local/share/plasma/plasmoids/org.eager.wallrefresh"
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -r plasmoid/org.eager.wallrefresh "$dest"
  echo "Widget installed. Restart the shell to load it:  kquitapp6 plasmashell; kstart plasmashell"
fi

# --- login screen (Plasma Login Manager only) --------------------------------
if [ "$WITH_LOGIN" = 1 ]; then
  if [ -f /etc/plasmalogin.conf ]; then
    img=$(awk '/^\[/{s=$0} s=="[Greeter][Wallpaper][org.kde.image][General]" && /^Image=/{sub(/^Image=file:\/\//,""); print; exit}' /etc/plasmalogin.conf)
    if [ -d "$img" ]; then
      for f in "$img"/contents/images/*; do sudo ln -sfn "$DIR/login.jpg" "$f"; done
      echo "Login screen: linked images in $img to $DIR/login.jpg"
    elif [ -n "$img" ]; then
      sudo ln -sfn "$DIR/login.jpg" "$img"
      echo "Login screen: linked $img to $DIR/login.jpg"
    else
      echo "No wallpaper set for the login screen yet: pick one in System Settings > Login Screen, then rerun with --login-screen." >&2
    fi
  else
    echo "/etc/plasmalogin.conf not found (SDDM?). Point your theme's background at $DIR/login.jpg manually; see README." >&2
  fi
fi

case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo "Note: $HOME/.local/bin is not in your PATH." ;; esac

cat <<EOF

Next steps:
  1. Edit $CONF (API keys, provider, categories)
  2. Run: wallrefresh
  3. Add the "Wallpaper Refresh" widget to your panel
EOF
