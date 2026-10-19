# Compress for Telegram

A macOS Quick Action that shrinks videos so they fit comfortably in a Telegram
message — right-click a file in Finder, pick **Quick Actions → Compress for
Telegram**, and get a much smaller `*_hevc.mov` next to the original.

No app, no menu-bar icon, no dependencies beyond `ffmpeg`.

## What it does

For any video:

- re-encodes to **H.265 / HEVC** (`libx265`, preset `slow`, CRF `28`)
- tags the stream `hvc1`, which is what QuickTime and Telegram need to play it
- copies the existing audio track untouched
- adds a silent AAC track when the source has no audio (Telegram handles such
  files badly otherwise)
- writes `<name>_hevc.mov` beside the source

For audio-only files it remuxes first (fixes fragmented AAC) and then encodes to
AAC — useful for voice notes and screen-recording audio.

Encoding runs in Terminal, so you see progress and can watch the size drop.

## Requirements

- macOS
- `ffmpeg` (includes `ffprobe`)

```bash
brew install ffmpeg          # Homebrew
sudo port install ffmpeg     # MacPorts
```

The script finds `ffmpeg` on `PATH` and falls back to `/opt/homebrew/bin`,
`/usr/local/bin`, and `/opt/local/bin`, so it works regardless of where your
package manager put it — including when launched from Finder, which does not
inherit your shell's `PATH`.

## Install

```bash
git clone https://github.com/vernikr/compress-for-telegram.git
cd compress-for-telegram
./install.sh
```

That copies two things into `~/Library/Services/`:

| Path | Role |
| --- | --- |
| `Compress for Telegram.workflow` | the Automator Quick Action |
| `encode_hevc.sh` | the encoding backend it calls |

Then right-click any video in Finder → **Quick Actions** → **Compress for
Telegram**.

If the item does not show up, enable it in **System Settings → Keyboard →
Keyboard Shortcuts → Services → Files and Folders**.

## Uninstall

```bash
./uninstall.sh
```

## Tuning

The backend reads three environment variables:

| Variable | Default | Meaning |
| --- | --- | --- |
| `CRF` | `28` | x265 quality; lower is better and bigger, `30`+ for smaller files |
| `PRESET` | `slow` | x265 speed preset; `medium` is roughly 2× faster |
| `AUDIO_BITRATE` | `32k` | AAC bitrate for audio-only inputs |

Because the Quick Action launches Terminal, the easiest way to use them is to
hardcode values in `~/Library/Services/encode_hevc.sh` or call the script
directly:

```bash
CRF=30 PRESET=medium ~/Library/Services/encode_hevc.sh clip.mp4
```

Batching works too — every argument is processed in turn:

```bash
~/Library/Services/encode_hevc.sh *.mp4
```

## Notes

- Output is `.mov`, not `.mp4`. HEVC-in-MOV with `hvc1` is the combination
  QuickTime and Telegram agree on.
- Re-encoding is lossy and not idempotent: running the action on an
  already-compressed file costs quality again. Keep the originals.
- The action is registered for Finder only, matching the original setup.
  Remove the `NSRequiredContext` block from `Contents/Info.plist` if you want it
  available from every app.

## Repository layout

```
Compress for Telegram.workflow/   Automator bundle (Info.plist, document.wflow, icon)
scripts/encode_hevc.sh            encoding backend, installed to ~/Library/Services
install.sh                        install for the current user
uninstall.sh                      remove it again
```

## По-русски

Быстрый доступ к сжатию видео для Telegram: ПКМ по файлу в Finder → **Быстрые
действия** → **Compress for Telegram**. На выходе рядом с оригиналом появляется
`*_hevc.mov` в H.265 — заметно легче исходника и нормально проигрывается в
Telegram и QuickTime.

Нужен только `ffmpeg` (`brew install ffmpeg`). Установка — `./install.sh`,
удаление — `./uninstall.sh`. Качество регулируется переменной `CRF`
(по умолчанию 28): больше — меньше файл.

## License

MIT — see [LICENSE](LICENSE).
