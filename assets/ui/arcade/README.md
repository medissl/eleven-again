# Arcade presentation assets — 1 November 2026

Production artwork uses the32 colours in `palette.json`, binary alpha and nearest filtering. Portraits, factual flags and kit colours retain their existing data and palettes. This is16-bit art direction, not a claim of an indexed32-colour framebuffer.

`sources.json` records the actual OpenAI image_gen prompts, original local output paths, target sizes and row-major atlas cells for all40 new fictional crests. Generated originals remain in the recorded generated-images folder and15 exact inputs are vendored under `art/arcade/sources/` with `.gdignore`; the source mapping uses portable project paths and retains original provenance paths. `tools/normalize_arcade_art.gd` admits those sources to production PNGs; it resizes/quantizes artwork without regenerating portraits. The normal game needs only the admitted files and no external service. The vendored source PNGs make deterministic normalization portable; no new image generation is needed to reproduce the admitted PNGs.

`tests/arcade_asset_checks.gd` checks all54 admitted images against imported opaque pixels, palette/dimensions/binary alpha,40 distinct badge hashes, stable numeral widths and36 pixel ability icons. Godot's transparent-border RGB repair is deliberately excluded from opaque-pixel comparison.

The small `kit.svg` is original functional icon geometry rasterized to16×16; event and ability glyph meanings are preserved through24×24 pixel admission. These functional symbols do not substitute for the generated board/pawn/lock/trophy illustrations.

## Font

Pixel Operator by Jayvee Enaguas (HarvettFox96), regular/bold/mono-bold, CC0 1.0. Downloaded from the [author's release page](https://www.dafont.com/pixel-operator.font) on1November2026; the author's original source repository link currently returns404. `fonts/LICENSE-PixelOperator.txt` preserves the supplied licence. All variants are from this single family; no font outlines were changed. The user's readability feedback superseded the initial Pixelify trial, which is not used or shipped in this asset set.

The background blur shader affects only the persistent decorative stadium. Match/HUD/text/cards do not sample that blur. The brief tunnel rush retains its existing cinematic blur; the artwork itself is pixel art.
