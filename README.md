# Dotfiles

## Installation

### Nix + Home Manager

1. Install [Determinate Nix](https://docs.determinate.systems/determinate-nix/):

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install
```

2. Clone dotfiles:

```bash
git clone git@github.com:MaxFangX/.dotfiles.git ~/.dotfiles
```

3. Apply home-manager config (uses `hostname -s` to select config):

```bash
~/.dotfiles/bin/hms
```

After first run, `hms` is in PATH. To upgrade Nix later: `just nix-upgrade`

### Font

lazy.nvim recommends installing a Nerdfont: https://www.nerdfonts.com/

I like "Menlo", so use "Meslo", a customized version of it:
https://www.nerdfonts.com/font-downloads

Install by opening in Finder and double clicking on the font:
- MesloLGMNerdFontMono-Bold.ttf
- MesloLGMNerdFontMono-BoldItalic.ttf
- MesloLGMNerdFontMono-Italic.ttf
- MesloLGMNerdFontMono-Regular.ttf

Notes:
- "LG\*" is font weight (LGL=Light, LGM=Medium, LGS=Semi-bold). Using LGM now.
- Don't need "Propo" (proportional) or "DZ" (alternate glyphs)

Configure iTerm2 to use the font: Settings > Profiles > Text > Font

This command can confirm whether the font was installed properly.

```vim
:echo join(map(range(0xE000, 0xF8FF), {_, v -> nr2char(v)}), '')
```
