# wallrefresh

Auto-refreshing wallpapers for KDE Plasma 6. One config file, one command, switchable providers, plus a panel widget with preview and a refresh button.

- **Providers:** Unsplash, Wallhaven, Pixabay, Picsum (add your own with one shell function)
- **Applies to:** desktop, lock screen and login screen (Plasma Login Manager) from a single download
- **Preferences:** keyword/category presets, minimum resolution, SFW-only filters
- **Panel widget:** preview, title (or photographer), provider picker and a Refresh button
- **Hourly timer:** a systemd user timer, optional

## Requirements

KDE Plasma 6, `bash`, `curl`, `jq`, `util-linux` (`flock`, `shuf`), and a systemd user session. Tested on CachyOS.

## Install

```bash
git clone <your-repo-url> wallrefresh && cd wallrefresh
./install.sh                  # script + config + timer + widget
./install.sh --login-screen   # also link the Plasma Login Manager wallpaper
```

Options: `--no-timer`, `--no-widget`, `--login-screen`.

Then edit `~/.config/wallrefresh.conf` (API keys, provider, presets), run `wallrefresh` once, and add **Wallpaper Refresh** to a panel (Add or Manage Widgets). If the widget doesn't appear, restart the shell: `kquitapp6 plasmashell; kstart plasmashell`.

## Usage

```bash
wallrefresh                # provider set by PROVIDER in the config
wallrefresh wallhaven      # force one provider for this run
wallrefresh random         # random provider from ROTATE, falls through on failure
wallrefresh list           # list available providers
```

The timer runs plain `wallrefresh`, so changing `PROVIDER` in the config changes the automatic refresh. No reload is needed.

## Configuration

Copy `config/wallrefresh.conf.example` to `~/.config/wallrefresh.conf` (the installer does this). Highlights:

| Setting | Meaning |
| --- | --- |
| `PROVIDER` | Default provider |
| `ROTATE` | Providers used by `random` |
| `WIDTH`, `HEIGHT` | Minimum or requested resolution |
| `UNSPLASH_QUERIES` | Keywords picked at random |
| `WALLHAVEN_PRESETS`, `PIXABAY_PRESETS` | `category\|keyword` pairs picked at random |
| `WALLHAVEN_EXCLUDE` | Tags excluded from Wallhaven searches |

**Never commit your real config**: it contains API keys. `.gitignore` already excludes it.

API keys: [Unsplash](https://unsplash.com/developers) (Access Key) and [Pixabay](https://pixabay.com/api/docs/) are free. Wallhaven needs no key for SFW results.

## How it works

1. A provider function picks a random preset and returns an image URL.
2. The image is saved as `/usr/local/share/wallpapers/wall-<timestamp>.jpg` (a new name each time, because Plasma caches wallpapers by path) and older downloads are deleted.
3. `login.jpg` in that folder is re-pointed at the new file, `plasma-apply-wallpaperimage` sets the desktop, and `kscreenlockerrc` is updated for the lock screen.
4. The path and a title are written to `~/.cache/wallrefresh/current.txt` for the widget.

The wallpaper folder must be writable by you and readable by everyone, because the login manager runs as another user. `install.sh` sets this up.

## Login screen

**Plasma Login Manager** reads a wallpaper package under `/var/lib/plasmalogin/wallpapers/`. First pick any wallpaper in System Settings > Login Screen, then run `./install.sh --login-screen`. It replaces the image(s) inside that package with a symlink to `login.jpg`. Applying a new wallpaper from System Settings can recreate the package, so rerun the command if the login screen goes back to the old image.

**SDDM** is not automated. Set your theme's background to `/usr/local/share/wallpapers/login.jpg` (for Breeze, in `/usr/share/sddm/themes/breeze/theme.conf.user`).

## Troubleshooting

- **Lock screen ignores the wallpaper:** it may be set to Picture of the Day or a slideshow. The script switches it to the image plugin on every run; check `cat ~/.config/kscreenlockerrc`.
- **Login screen shows the old image:** check that the `plasmalogin` user can read the file (`namei -l /usr/local/share/wallpapers/login.jpg`) and rerun `./install.sh --login-screen`.
- **Widget shows nothing:** run `wallrefresh` once, then `cat ~/.cache/wallrefresh/current.txt`. For QML errors: `plasmoidviewer -a org.eager.wallrefresh` (package `plasma-sdk`).
- **Timer doesn't fire:** `systemctl --user list-timers wallrefresh.timer` and `journalctl --user -u wallrefresh.service -e`.
- **Debug a provider:** `bash -x ~/.local/bin/wallrefresh wallhaven`.

## Notes on provider terms

- **Unsplash:** the script sends the required download ping and shows the photographer in the title; keep that attribution if you redistribute images.
- **Pixabay:** asks that API results be cached and not hammered; one request per hour is fine.
- Image content is up to each service. `purity=100` (Wallhaven), `safesearch=true` (Pixabay) and `content_filter=high` (Unsplash) are enabled, but no filter is perfect.

## Uninstall

```bash
./uninstall.sh          # keeps your config
./uninstall.sh --purge  # also deletes it
```

## License

MIT
