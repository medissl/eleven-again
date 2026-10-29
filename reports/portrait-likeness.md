# Modular likeness correction

29 October 2026. UI checkpoint: `a8d1a7f`; work branch: `codex/portrait-likeness`.

The user explicitly requested reusable pieces and existing modular assembly,
not generated standalone portraits. The earlier whole-portrait draft was never
integrated. The original 51-piece compiler reproduced all 200 runtime sprites
pixel for pixel before changes. Its self-contained continuation now lives in
`art/portraits/`, with editable geometry, semantic palettes, recipes and an
offline Pillow composer. Runtime remains baked 96×96 RGBA PNGs.

First batch: 39 additional interchangeable pieces (90 total) and twenty
individually referenced recipe corrections. These cover Beckham's close shave,
Messi's period part/nape, Cristiano's wider quiff, Ronaldo's 1996–97 shave,
Ronaldinho's tied curls, Cruyff/Beckenbauer's period hair, Maradona's fuller curls,
Pelé's compact curls, Yashin's cap, and differing faces/brows/noses/mouths/beards.
Generic shirts, identifiers, stats, traits, card layout and gameplay are unchanged.
The other 180 portraits remain pixel-identical and individually unreviewed.

Sources and visible cues are recorded per card in
`outputs/portrait-likeness-v1/review.json`. Some available photographs are from
adjacent editions or secondary reproductions; the ledger states those limits.
No photo pixels or kit branding are copied into game art. This is a stylized
likeness pass, not a claim of photographic accuracy or individually established
dates for every source. The user responded positively to the first batch and
requested wider coverage.

Verification: all 90 part definitions and 200 recipes validate; exactly twenty
runtime pixel images changed and the catalogue SHA-256 stayed unchanged.
Godot 4.7.2 import passed. Existing catalogue checks and native card UI checks
passed for all 200 bindings, hidden/missing art, archive search/paging and
inspection/comparison input. Actual CardView captures at 1280×720 and
1920×1080 were inspected (`outputs/portrait-likeness-v1/native-*.png`).
Logs: `portrait-import.log`, `portrait-catalogue.log`, `portrait-card-ui.log`,
`portrait-native.log`. No export, publishing or GitHub push performed.

Continue through the remaining roster in position groups, inspecting period
photos and adding only needed reusable pieces. Keep the per-card ledger honest;
distinct assemblies and passing bindings do not substitute for likeness review.
