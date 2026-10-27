# Image generation record

Built-in image generation was used. These prompts document the visual reference; they are not implementation instructions or evidence of a running Godot scene.

## Initial concept prompt

Use case: ui-mockup.
Create a finished, beautifully art-directed PC GAMEPLAY SCREEN for Eleven Again, a football squad roguelike built in Godot. This is a visual implementation reference, not a website, promotional poster, wireframe or dashboard. One uninterrupted 16:9 image, target 1920x1080. Render only the game screen, no monitor/device/browser/frame, no annotations outside the UI.
Input image 1 is the current criticised prototype, supplied ONLY to understand top-down football and named circle players. Redesign its appearance and information hierarchy completely. Its redundant headings, debug text, statistics and toolbar must disappear.

Art direction: polished indie football tactics board, restrained television-broadcast typography, rich natural dark-green mown turf with very subtle fine grain, elegant thin chalk lines, matte near-black forest surround, warm ivory type, muted coral opposing team, minimal warm amber selection accent. Flat orthographic 2D full-pitch view, no camera perspective, no large stadium, no photoreal footballer bodies, no excessive glow or glass. Give it craft and atmosphere without clutter. Sharp clean legible humanist sans serif, tabular scoreboard numerals, generous spacing, balanced fine linework, visually far more finished than the reference.

LAYOUT:
The top-down horizontal full football pitch is the hero, occupies about 78% of usable width, with accurate 105:68 aspect ratio. All four touchlines, both goals with subtle nets outside the lines, centre circle, halfway line, penalty boxes and arcs are entirely visible. Large field from near the top HUD down to near bottom edge, no wasted footer. Outer margins about 32px. Compact commentary column on the right around 280-310px, separated by quiet breathing space and a fine hairline. No bottom HUD, instruction bar, bench, stats chart or formation legend.
A single compact scoreboard directly above the pitch, centred on the PITCH area: small cream kit symbol, 'MEADOW XI', large '2 – 1', 'HARBOR XI', small coral kit symbol. A small amber '67′' under or beside the score. Clean alignment; no huge panels, no page title, no game logo, no match caption, no competition breadcrumb.
Top-right above commentary: compact pause icon button, a segmented '1×' '2×' speed selector with '1×' clearly selected, then hamburger icon with a small 'Menu' label. No kickoff button, restart button or quit button in the persistent HUD.
Right column: a tiny green live dot and 'LIVE' heading, then sparse well-designed recent event rows. Each row has a narrow minute column, simple meaningful icon and one or two concise text lines, beautifully typeset with clear spacing, no card surrounding every row. Event texts, newest first:
'67′' 'Ward' 'Save'
'64′' 'Dimas ↑  Bima ↓' 'Substitution'
'61′' 'Bauer' 'Yellow card'
'54′' 'Amir' 'Goal'
'38′' 'Rossi' 'Goal'
'22′' 'Reed' 'Goal'
Use tiny team-colour ticks to identify side. Home goals Amir and Reed, away goal Rossi consistent with 2–1. Emphasise goals with restrained icon and type, not giant announcement. Bottom of the event column contains only a quiet 'All events' text affordance. No shots/pass/on-target tables, no progress tracks or generic analytics.

FIELD CONTENT:
Exactly 22 circular player markers: eleven warm ivory home discs and eleven muted coral away discs. Home discs have dark numbers; away discs use a contrasting light ring and a small stripe cue so teams differ beyond colour. Subtle grounded shadows, refined small numbers inside, readable short surnames below in off-white with restrained dark halo. They look like premium tactical tokens, not real human sprites, not photos. Names not boxed in heavy rectangular labels. Spread players in a believable mid-match attacking phase, with goalkeepers near opposing goals, defenders holding shape and midfielders finding space; no rigid kickoff diagram, no swarm, no duplicated ball. Optional names to use include Ward, Hart, Okoro, Silva, Sato, Reed, Costa, Idris, Dimas, Noor, Amir for ivory; Novak, Chen, Bauer, Dube, Park, Vega, Leone, Musa, Rossi, Ilyas, Kova for coral.
A single small, crisp white ball with dark outline near ivory Noor in the right-middle attacking channel. Noor has a thin muted amber possession/inspection ring. Markers and the ball are unmistakable against the field, surnames have collision-free spacing. No arrows, dashed trails, target lines, heatmaps, damage numbers or developer gizmos.

Hard exclusions: no 'ELEVEN AGAIN' title, no 'EXHIBITION', no 'MATCH LAB', no 'THE MATCH', no 'MATCH JOURNAL', no 'fictional squads', no 'phase 1', no 'kick off', no visible restart/quit buttons, no help/debug footer, no instructional paragraphs. Final screen should feel calm, readable, finished and actually playable.

## Targeted correction prompt

Edit the supplied finished football gameplay UI with one precise correction. Preserve the full image, layout, scoreboard, text, field, controls, live feed, existing player names and positions, lighting, textures and every other detail exactly. It currently contains eleven ivory home players but only ten coral away players. Add the missing eleventh away player: one coral circular token with white outline and number 10, surname "Kova" beneath, at approximately x=385 y=510 in this 1672x940 image, in the open left-central channel between the left penalty area and ivory Reed. Match the existing coral token size, type, label shadow and rendering exactly. Do not add a second ball. Do not remove, move, duplicate, or rename existing players. Final total must be exactly 22 players: 11 home including Ward and 11 away including Novak and new Kova. Preserve the two green goalkeeper tokens. This is the sole intended change.

## Selected deliverable

`match-live-concept.png` is the corrected image. The screenshot supplied by the user was a content reference and a record of the rejected UI, not a layout to reproduce. The resulting image was inspected visually. No Godot code was edited or runtime UI tested for this concept-only request.

