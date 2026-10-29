# Matchday v4 implementation — 29 October 2026

Scope: complete supplied UI/asset integration plus whole-team football improvements. Read outputs/full-ui-revamp-v4/MATCH_UPGRADE_ADDENDUM.md first: the stripped match references are withdrawn. Upgrade the textured native renderer; uniform 26–28px bodies, complete names, detailed goals, a crisp ball and real action/trait motion remain required. Existing fixed ticks, 180 seconds, saved state/economy and original CardView/portraits are preserved.

## Slice 1 — theme and private Collection

Promoted original SVG components/white glyphs/art/fonts/licences into assets/ui/matchday. Theme uses pine/chalk/sage/brass, Barlow Semi Condensed and Source Sans3; CardView keeps its own original fonts/template. Runtime menu uses the actual wordmark/cover, separate Collection and Records rows, valid disk preview and complete best-owned cards. Campaign screens use a 1280×720 logical canvas that scales to1080p without a user zoom preference. Recruitment/market use the new hierarchy/skin and full cards. Event symbols now bind to the supplied white family (literal cards retain colour).

Collection uses existing exact-version profile discoveries, 12 entries/page and identical anonymous hidden backs. Identity filters/search use discovered entries only. Hidden inspection contains no definition/metadata. Acquired, current owned and historical record contexts remain inspectable. Ordinary campaign preparation opens Collection; the unrestricted catalogue is isolated to the development exhibition. No profile reset, acquisition gating or permanent power was added.

Checks: empty/partial/full/search/filter/privacy native checks pass; existing200-card UI checks pass. Native full campaign flow and card bounds passed720p/1080p; two executable launches preserve the exact next600 ticks with persisted settings. Graphify does not index this repository, so local sources were used. A fresh unchanged-football baseline reproduced3.55 goals/16.85 shots/77.25 completed passes over20 fixtures,4 fouls/2yellows/13parries and no natural corners/throws/penalties/offsides/reds. Raw baseline is matchday-baseline.log.

## Slice 2 — native screen integration and match presentation

The new home/Continue compositions now use the supplied wordmark, cover, separate actions, valid disk preview and complete owned cards. Origin is a six-country grid with an actual XI preview. Campaign fixtures are compact tickets with real reveals/scouting. Preparation is a pitch/marker selector with reserves, legal assignment, all tactics, takers, shootout order, bench priority and pinned substitutions. Preview uses the real textured pitch renderer in an isolated frozen model; it renders all eleven players and consumes no campaign RNG.

Recruitment uses five complete 232×324.8 native cards; market uses four 212×296.8 cards, actual prices, aligned facts, compact navigation and the primary in the footer. A 432px replacement drawer previews actual outgoing/fee/fit/funds. Cancel restores draft facts without mutation; one confirmation commits the existing atomic transaction. Insufficient cash/signing-limit reasons remain visible. Paging and modal cancellation restore focus.

Display/Audio/Controls/Accessibility are separate native settings sections, with the supplied slider/toggle assets and unchanged persisted semantics. Records has honest empty/history states and a read-only saved XI pitch. Inspector pin/source controls are keyboard reachable; comparison uses two full cards with a one-line heading, the supplied comparison glyph, honest role mismatch and fit deltas only in an actual compatible selected slot. Confirmations/recovery use the supplied panel grammar and retain original save files.

Live match/pause/reports/goal now share Matchday typography and simple white glyphs. Pass delivery icons use actual through/cross/lob event metadata. The existing full markings, arcs and deep nets remain; turf contrast/grain is refined and its deterministic texture is shared by previews/matches. All bodies retain the same 26.4px diameter plus equal shadow treatment, selection/trait rings are external, surnames remain stable below, and the ball is crisp with height/rolling/shadow. Real trait states drive white signature glyphs and failure/partial labels. Actor/name emphasis softens consistently beneath the native italic goal/sweep/confetti. No simulation, attribute, content, economy, save-schema or RNG code changed in this slice.

Verification on Godot 4.7.2 GL Compatibility:

- Native `campaign_ui_checks.gd` at 720p and 1080p passes complete-card bounds, authored twelve-win/three-defeat decisions, actual keyboard/mouse, replacement cancel/commit, all preparation/settings sections, nested historical inspection and recovery. Captures were inspected; the static-preview kickoff fade and comparison title wrapping were found and corrected.
- `card_ui_checks.gd` passes 200 bindings, hidden/missing art, keyboard pin/source/Back and comparison at both resolutions. `collection_checks.gd` passes empty/partial/full, pagination and hidden identity/search/filter non-disclosure.
- `team_layout_checks.gd` passes 24 gameplay/pause/halftime/details/full-time identity cases at both resolutions. `capture_match.gd --ticks=1800 --verify-controls` passes native controls at both sizes; an authored shootout-result scenario also passes with separate shootout tally.
- Separate `--write-ui-probe matchday_ui_final` / `--resume-ui-probe matchday_ui_final` processes reproduce the exact next 600 ticks and persisted sound. Disposable files were cleaned.
- Actual campaign motion passes 2× physics, pause/menu/resume, halftime/Continue and a genuine final result. Native 70-frame goal→kickoff sequences were captured at 1× and 2×, with the final actor fade rechecked at 2×. Sequences live under ignored `.godot/presentation-frames/`; they are not performance benchmarks.
- Headless import/parse and diff whitespace checks pass. Logs: `reports/matchday-{campaign-720,campaign-1080,card-ui,collection,team-layout,native-match,shootout,save,resume,campaign-motion,motion-goal,motion-goal2x,import}.log`.

Human approval of the new match look, OS display-scaling/export and measured football realism/balance remain open. Reference32 is the read-only saved XI; reference28 is a design component sheet, not an extra user-facing game menu.

## Next authorized work

The user reprioritized portrait likeness **after this UI checkpoint** on 29 October: review important cards one by one against era-appropriate photos, starting with the Beckham fauxhawk complaint, preserving pixel style/template/stats. Task6.3 records the reopened work. Keep changes and source/review evidence separate from this UI commit.

The broader football-quality pass is still unfinished: residual pass momentum/friction/touch/keeper cross handling; coordinated roles/team phases/limited perception; pass/action selection and genuine foul/offside adjudication; stratified natural-match telemetry and deterministic snapshot gates. Do not force goals or event quotas. The original twenty-fixture baseline remains unchanged; scenario tests and UI captures do not prove natural event frequency or realism.

Local branch: `codex/ui-reference-completion`, based on the earlier `f4d9c2e` asset/Collection checkpoint. Design branch and unrelated edits were preserved. No push/merge/export.
