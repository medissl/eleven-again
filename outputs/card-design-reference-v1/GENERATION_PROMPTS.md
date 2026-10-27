# Card concept generation prompts

The built-in image-generation tool was used for both outputs. The supplied photograph and user reference were inspected first. No CLI/API fallback was used.

## Transparent portrait

Use case: background-extraction / identity-preserve. Edit the supplied CC0 archival photograph of Johan Cruyff, 26 May 1974. Produce a clean transparent-background PNG portrait cutout for a football player card. Preserve his exact face, likeness, expression, hair, clothing, monochrome photographic appearance and pose from the supplied photograph. Do not redraw, beautify, colourise, change his age, invent details or replace him with a generated lookalike. Remove only the entire stadium, spectators and surrounding background, with careful hair edges, no white/black halo, no remaining background fragments. Crop to head and upper torso, with the whole hair and both shoulders visible; trim below upper chest so the lower shirt emblem is outside the crop. Keep comfortable transparent space above the hair and a little beside the shoulders. Actual alpha transparency, no checkerboard baked into pixels, no solid background, no border, no shadow, no text, no card frame. The photographic subject alone.

## Card concept sheet

Use case: ui-mockup / visual design reference.
Create a stunning, original PLAYER CARD DESIGN CONCEPT SHEET for Eleven Again, a personal football squad-building roguelike. Landscape approximately 16:10, high-resolution finished game UI art, not a photograph of physical cards. Show THREE beautiful crisp fully visible cards on a quiet near-black forest background with generous gutters: a large hero LEGEND card on the left, a slightly smaller PROFESSIONAL card in the middle, and an UNDISCOVERED index card on the right. All share the same 5:7 card proportions and underlying layout. One discreet sheet heading "ELEVEN AGAIN / PLAYER ARCHIVE", no long paragraphs, no callout arrows, no device, no browser. The cards are the entire focus.

INPUT ROLES:
Image 1: supplied black-and-white Cruyff transparent cutout. This is the portrait to composite into the left card. Preserve the actual supplied facial likeness, expression, head angle, hair and monochrome photographic character. Do not invent a lookalike or replace him with another footballer.
Image 2: supplied FIFA-like generic gold silhouette card. This is ONLY a content reference for rating, position, portrait, name and six attributes. Do NOT copy its shield silhouette, crown, crest, filigree, gold marble triangles, brand assets or ornament.

DESIGN DIRECTION:
Ownable sports archive / collector's album aesthetic paired with a contemporary tactical game. Straight-sided rectangular card with a single clipped upper-right corner and modest 8px lower radii, a narrow dark forest binding spine at the left, fine inset rules, elegant large condensed numerals and confident clear sans-serif name. Warm ivory paper, subtle archival fibre, forest-black, restrained antique brass edge inlay only for Legend, small warm amber/orange archival year stamp. Ghosted pitch-centre-circle geometry behind the portrait provides a uniquely football motif without busy artwork. A prominent beautifully isolated cutout portrait occupies the upper 60%, coming forward from the subtle circular field motif, shoulders blending gracefully into the nameplate. Precise hierarchy and optical alignment, tactility without fake heavy bevels or holographic chaos. Do not make a FIFA/EA shield, generic fantasy RPG card, neon trading card, or excessively ornate playing card. No crowns, laurels, licensed logos, sponsor badges or club crests. Modern, collectible and emotional.

LEFT HERO CARD:
Warm ivory and deep forest with restrained brass edge, exact authentic Cruyff cutout as supplied.
Upper-left large "110", below it small "AM".
Upper-right under clipped corner a compact archival stamp "1974".
A narrow clear upper or lower strip states "LEGEND", with a tiny geometric XI monogram.
Name below portrait: small "JOHAN" then much larger "CRUYFF".
Country line: tiny horizontal Netherlands flag and "NETHERLANDS".
One understated trait row with a simple passing-lane icon and "THREADER".
Bottom contains six beautifully legible data cells in TWO ROWS of THREE, consistent precise columns, labels small but readable and values dominant:
row one: "PAC 109" | "SHO 108" | "PAS 114"
row two: "DRI 116" | "DEF 55" | "PHY 88".
These are deliberately authored concept ratings, not EA data; render exactly. No prices, buy buttons, percentages, health bars, arbitrary serials or fake biography on the card. Head and text must not overlap.

MIDDLE PROFESSIONAL CARD:
Same template and matching information layout, quieter materials: matte forest with warm ivory typography, thin pale edge, no brass spectacle.
An original fictional male footballer around 25 with short dark curls in a plain green football shirt, chest-up cutout photographic portrait, no resemblance to a named real athlete, no crest, no sponsor. Portrait must be recognisably different from Cruyff.
Upper-left "82", below "CM". Top-right stamp "FICTIONAL".
Band label "PROFESSIONAL".
Name small "MATEO", large "SILVA".
Country line tiny Brazil flag and "BRAZIL".
Keep a quiet trait-space divider without inventing a gameplay ability.
Bottom exact same TWO ROWS of THREE:
"PAC 78" | "SHO 73" | "PAS 88"
"DRI 82" | "DEF 76" | "PHY 80".
Make ordinary players attractive and readable rather than disposable gray junk.

RIGHT UNDISCOVERED CARD:
Same outer shape, binding spine and portrait proportions, slightly worn matte charcoal/forest paper and fine muted ivory inset edge, no shiny tier treatment. A softly printed anonymous head-and-shoulders silhouette in the portrait zone, with one small discreet lock or question-mark emblem. Lower name field only "UNDISCOVERED". Six attribute positions use anonymous dashes rather than values. No rating, no country flag, no year, no player name, no positional label, no rarity band and no identifying details. It should feel like an empty space waiting to be filled in a beloved football album, not a locked microtransaction.

Quality: beautifully aligned product-specific game components with readable exact typography, crisp images, coherent palette, subtle shadow, no long text, no extra thumbnails, no surrounding mock website. Card borders and entire bottoms visible. Final art looks like a serious independently designed football roguelike rather than a reskinned Ultimate Team card.

## Output use

The selected portrait is `cruyff-1974-cutout.png`; the selected concept sheet is `player-card-concept.png`. These are design/example assets. Text and ratings should be recreated from game data in a native card component, not baked into a unique bitmap per player. Neither prompt authorises changing the active gameplay implementation.

