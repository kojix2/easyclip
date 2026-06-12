# EasyClip

[![test](https://github.com/kojix2/easyclip/actions/workflows/test.yml/badge.svg)](https://github.com/kojix2/easyclip/actions/workflows/test.yml)
[![Lines of Code](https://img.shields.io/endpoint?url=https%3A%2F%2Ftokei.kojix2.net%2Fbadge%2Fgithub%2Fkojix2%2Feasyclip%2Flines)](https://tokei.kojix2.net/github/kojix2/easyclip)

Crystal module for clipboard interaction.

## Installation

Add to `shard.yml`:

```yaml
dependencies:
  easyclip:
    github: kojix2/easyclip
```

Run `shards install`

## Usage

```crystal
require "easyclip"

# Copy 'text' to clipboard
EasyClip.copy("text")

# Paste text from the clipboard
str = EasyClip.paste
```

### Linux

Detects the current session and available tools at runtime:

- Wayland: `wl-copy` / `wl-paste`, then X11/XWayland fallbacks
- X11 copy: `xsel`
- X11 paste: `xclip`, then `xsel`
- WSL: `clip.exe` (copy), `powershell.exe` (paste)
- Termux: `termux-clipboard-set` / `termux-clipboard-get`

Install what fits your session, e.g. `sudo apt install wl-clipboard xclip xsel`.

Commands come from a fixed allowlist, run without a shell, and receive text via stdin.

### Windows

Uses the native Win32 clipboard API (`CF_UNICODETEXT`): no child process, no
trailing-newline quirk. WSL runs as a Linux binary and uses the Linux fallbacks
above instead.

## Contributing

1. Fork (<https://github.com/kojix2/easyclip/fork>)
2. Feature branch (`git checkout -b new-feature`)
3. Commit (`git commit -am 'Add feature'`)
4. Push (`git push origin new-feature`)
5. Pull request

## License

MIT
