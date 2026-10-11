#!/usr/bin/env bash
# Removes wallrefresh for the current user. Keeps your config unless --purge.
#   ./uninstall.sh [--purge]
set -euo pipefail

PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1

systemctl --user disable --now wallrefresh.timer 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/wallrefresh.service" "$HOME/.config/systemd/user/wallrefresh.timer"
systemctl --user daemon-reload

rm -f  "$HOME/.local/bin/wallrefresh"
rm -rf "$HOME/.local/share/plasma/plasmoids/org.eager.wallrefresh" "$HOME/.cache/wallrefresh"

if [ "$PURGE" = 1 ]; then
  rm -f "$HOME/.config/wallrefresh.conf"
  echo "Config removed."
else
  echo "Kept $HOME/.config/wallrefresh.conf (use --purge to delete it)."
fi

echo "Downloaded wallpapers in /usr/local/share/wallpapers were left in place."
echo "Remove the widget from your panel and restart the shell: kquitapp6 plasmashell; kstart plasmashell"
