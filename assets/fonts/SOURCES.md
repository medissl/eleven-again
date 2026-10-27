# Packaged interface fonts

Downloaded 27 October 2026 from the official Google Fonts distribution. No runtime network access is used. Font binaries are unmodified; the Inter filename alone is simplified locally.

- Barlow Condensed Bold, SemiBold and BoldItalic: https://github.com/google/fonts/tree/main/ofl/barlowcondensed . Jeremy Tribby / The Barlow Project Authors. License retained as `Barlow-OFL.txt`.
- Inter variable regular (`Inter[opsz,wght].ttf`): https://github.com/google/fonts/tree/main/ofl/inter . Rasmus Andersson / The Inter Project Authors. License retained as `Inter-OFL.txt`.

`ui/game_theme.tres` defines body, strong body, heading, stable-numeral score, section and goal roles. These approximate the user's generated references; the references do not identify an exact font. Required Latin/diacritic, arrow, minute-prime and score/control glyphs are checked in Godot; the engine fallback handles unsupported scripts.
