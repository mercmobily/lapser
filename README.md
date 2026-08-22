# Lapser

Lapser records Linux desktop work as lightweight time-lapse videos. It takes
one screenshot every 15 seconds and turns the screenshots into an MP4 at four
frames per second, so one hour of work becomes one minute of video.

## Features

- Full-screen capture and portal-selected window capture
- Independent profiles with labels and timestamped screenshots
- Thumbnail browsing, selection, deletion, and undo
- MP4 conversion with progress and cancellation
- Separate pending, uploaded, and discarded video views
- Work-time summaries and manually entered work videos

## Single-file source

All application code, including the GTK stylesheet, is contained in the
executable [`lapser`](./lapser) file. It does not depend on assets or modules
from this repository. Runtime data is created under `~/.lapser`.

Lapser is a single-file Python application, not a statically linked binary. It
still requires the Linux desktop libraries and media tools below.

## Requirements

- Python 3 with PyGObject bindings for GTK 4, libadwaita, Pango, and GStreamer
- `python3-dbus`, an XDG desktop portal, PipeWire, and the relevant GStreamer
  plugins for selected-window capture
- `gnome-screenshot` and `gsettings` for full-screen capture
- ImageMagick's `convert` command for annotations and thumbnails
- `ffmpeg` and `ffprobe` for video generation and duration reporting

On Ubuntu 24.04, the dependencies can be installed with:

```sh
sudo apt install \
  python3-gi python3-dbus \
  gir1.2-gtk-4.0 gir1.2-adw-1 gir1.2-pango-1.0 gir1.2-gstreamer-1.0 \
  gnome-screenshot imagemagick ffmpeg \
  gstreamer1.0-pipewire gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
  xdg-desktop-portal xdg-desktop-portal-gnome
```

## Install and run

```sh
install -Dm755 lapser "$HOME/.local/bin/lapser"
"$HOME/.local/bin/lapser" --check-deps
"$HOME/.local/bin/lapser"
```

The dependency check reports each unavailable feature separately. Lapser keeps
all screenshots, logs, and videos locally. Marking a video as uploaded only
moves it into Lapser's uploaded view; the application does not transfer it to a
remote service.

## License

MIT
