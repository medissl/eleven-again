# Authored match fixtures

`exhibition_roster.tres` and `specialist_roster.tres` are original fictional, unbalanced test squads with immutable native player Resources. They use role-shaped profiles, stable IDs and the GDD/v2 card arithmetic. No external football ratings or historical portraits were imported. The Specialists option makes the seven specialties missing from the original exhibition roster available through pre-match lineup/taker selection; it is a fixture squad, not a free skill-equipment system.

`traits.json` adapts only the 36 original definitions and parameters from `outputs/football-research-v1/04_DESIGN_DATA.json`. The research's proposed 300-second match configuration is deliberately excluded: the user's confirmed 180 active seconds remain authoritative. Trait constants are provisional tuning, not established balance. There is one trait per card, no OVR multiplier or rarity multiplier. Native simulation code owns eligibility, caps, actual effects and outcomes; the JSON is not an executable scripting language.

The newer four-tier ranges and role/keeper weights come from `outputs/card-system-v2/IMPLEMENTATION_GUIDE.md` and its `sources/rules.json`. Runtime card presentation, portraits, recruitment/economy and the permanent index remain separate from these match fixtures.

Three-minute adaptation: Overlap Engine has `activation_stamina_cost: 0`; its short 15% work-saving window otherwise saves less than the generic two-point activation fee, making its sole benefit net negative. Uses, cooldown, cover requirement and work saving remain bounded. This is a provisional tuning exception, not a balance finding. Other activations cost two stamina; shootout specialties have a separate one-opportunity budget per kick.
