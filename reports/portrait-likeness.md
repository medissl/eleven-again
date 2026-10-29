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

## Second batch: keepers and distinctive accessories

Twenty more assemblies are replaced: the remaining seventeen keepers, Edgar
Davids, Roberto Baggio and Victor Osimhen. Coverage is now **40/200**, including
all twenty keepers; 160 individual reviews remain. Fifteen additional pieces
bring the editable kit to **105**. These include differentiated dense beards,
curly fades, short tapers, brushed/spiky/wavy crops, a dyed top with dark sides,
low curly ponytail, compact loose locks, neck-ink impression and protective mask.
Mask eye holes explicitly remain transparent. Generic shirts and all card data
remain unchanged, checked against the original catalogue SHA-256.

Period handling matters: Čech's 2004–05 study remains helmet-free. Davids's
inspected 2000 image visibly carries a later date and goggles; this accessory
was not assigned to 1997–98. An initially mistaken Poland-kit reading of the
Martínez photo was corrected after the full-body image showed the AFA crest.
The ledger records actual sources and adjacent-year/monochrome limitations.
The Baggio tail is supported by front and dated 1994 rear studies; Osimhen's
mask/top reference is from the adjacent December 2023 Napoli edition.

Second-batch checks: 105 pieces/200 recipes validated, 200 distinct assemblies,
twenty new replacements only, native import, all catalogue/card UI checks and
actual 720p/1080p CardViews passed. Captures:
`outputs/portrait-likeness-v1/native-keepers-1280x720.png` and the 1080p equivalent.
Logs: `portrait-keepers-{import,native,catalogue,card-ui}.log`.
Next coherent group: recognizable outfield stars and the remaining position
groups, with the same individual source/era review before replacement.
