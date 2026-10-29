# Editable modular portrait source

Continuation of `outputs/card-system-v2/sources/{parts,palettes}.json` and
`outputs/player-catalogue-200-v1/data/portrait_recipes.json`. Those original
authoring packages are preserved. The copied composer was checked against all
200 runtime images before editing: every RGBA pixel matched.

`parts.json` holds the original pixel-grid polygon/rectangle/line commands and
new interchangeable pieces. `palettes.json` supplies semantic colour ramps.
`recipes.json` chooses eight pieces and skin/hair/shirt palettes for each stable
portrait ID. No photograph, generated full portrait, network access or RNG is
used in assembly. Pillow is an offline authoring dependency, never a game one.

All pieces share a transparent **96×96** canvas. Preserve the attachment grid:
head includes neck/ears; eyes around y38–42, brows y33–36, nose y44–55, mouth
y57–64. Order is hair back, head, shirt, eyes, brows, nose, mouth, facial hair,
hair front. Hair/headwear belongs to the existing hair category. Keep integer
geometry, opaque pixels, original padding and nearest filtering.

```powershell
python art/portraits/render.py
python art/portraits/render.py --parts outputs/portrait-likeness-v1/parts
python art/portraits/render.py --export outputs/portrait-likeness-v1/assembled
python art/portraits/render.py --export assets/portraits/catalogue_200 --only david_beckham_2000_01
```

First inspect the assembled candidate against the edition reference and actual
native CardView before promoting it. Export only the reviewed selection into
runtime. All card identifiers, metadata, stats, traits and generic shirts stay
unchanged. Individual sources, era caveats and progress are recorded separately
in `outputs/portrait-likeness-v1/review.json`; an assembly passing validation does
not establish human approval or photographic likeness.

The authoring folder is `.gdignore`d. Godot continues to load the existing baked
PNGs from `assets/portraits/catalogue_200/`; no runtime compositor is introduced.

Native verification must compare loaded opaque texture pixels with the baked PNG,
not just dimensions. Refresh imports with `Godot --headless --editor --path . --import`
(without an additional immediate `--quit`) before running `capture.gd`. The capture
script rejects stale imported art, then records actual cards at both resolutions.
