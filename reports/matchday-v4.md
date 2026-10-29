# Matchday v4 implementation — 29 October 2026

Scope: complete supplied UI/asset integration plus whole-team football improvements. Read outputs/full-ui-revamp-v4/MATCH_UPGRADE_ADDENDUM.md first: the stripped match references are withdrawn. Upgrade the textured native renderer; uniform 26–28px bodies, complete names, detailed goals, a crisp ball and real action/trait motion remain required. Existing fixed ticks, 180 seconds, saved state/economy and original CardView/portraits are preserved.

## Slice 1 — theme and private Collection

Promoted original SVG components/white glyphs/art/fonts/licences into assets/ui/matchday. Theme uses pine/chalk/sage/brass, Barlow Semi Condensed and Source Sans3; CardView keeps its own original fonts/template. Runtime menu uses the actual wordmark/cover, separate Collection and Records rows, valid disk preview and complete best-owned cards. Campaign screens use a 1280×720 logical canvas that scales to1080p without a user zoom preference. Recruitment/market use the new hierarchy/skin and full cards. Event symbols now bind to the supplied white family (literal cards retain colour).

Collection uses existing exact-version profile discoveries, 12 entries/page and identical anonymous hidden backs. Identity filters/search use discovered entries only. Hidden inspection contains no definition/metadata. Acquired, current owned and historical record contexts remain inspectable. Ordinary campaign preparation opens Collection; the unrestricted catalogue is isolated to the development exhibition. No profile reset, acquisition gating or permanent power was added.

Checks: empty/partial/full/search/filter/privacy native checks pass; existing200-card UI checks pass. Native full campaign flow and card bounds passed720p/1080p; two executable launches preserve the exact next600 ticks with persisted settings. Graphify does not index this repository, so local sources were used. A fresh unchanged-football baseline reproduced3.55 goals/16.85 shots/77.25 completed passes over20 fixtures,4 fouls/2yellows/13parries and no natural corners/throws/penalties/offsides/reds. Raw baseline is matchday-baseline.log.

## Remaining implementation order

1. Complete replacement/filter drawers, all origin/preparation/settings/record/inspector/terminal compositions and native interactions. Current legacy layouts are not all v4 complete.
2. Fix physical opportunity suppression (residual pass momentum, friction, touch/deflection and keeper cross handling), with causal boundary and future-snapshot tests.
3. Coordinate every role/team phase and limited perception; improve passing/action selection and actual foul/offside adjudication without event quotas.
4. Upgrade actual textured match/HUD/ball/player/trait/goal rendering and record native before/after plus1×/2× action clips. Never copy the withdrawn flat pitch.
5. Stratified natural-match telemetry, deterministic/snapshot/disk checks and final complete-screen acceptance. Human realism/balance and user visual approval remain open.

Local branch codex/matchday-v4 started at5b5848c; design branch untouched. No push/merge/export.
