# Eleven Again audio credits

Downloaded 30 October 2026. Audio bytes are unchanged; selected files were renamed. `manifest.json` records the closed roster, source member, source package hash and runtime-file SHA-256. The original downloads and source-page HTML are retained locally in ignored `.godot/audio-downloads/`. No EA audio was copied.

- **Menu Music** — **wipics**, [author's release](https://opengameart.org/content/menu-music-1), [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). `menu.ogg` is the author's exact `menu_3.ogg` synth/drum loop. An independently downloaded similarly named file was rejected; it is not shipped.
- **Interface Sounds** and **Impact Sounds** — **Kenney**, [interface package](https://kenney.nl/assets/interface-sounds), [impact package](https://kenney.nl/assets/impact-sounds), [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). Original package licence texts are included. Selected clicks/focus/confirmation/back cues and soft/punch impacts serve as restrained football foley; these are not claimed as recordings of actual football boots or nets.
- **Free Crowd Cheering Sounds** — **Gregor Quendel**, [author's release](https://opengameart.org/content/free-crowd-cheering-sounds), [author](https://www.gregorquendel.com/), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Original MP3 members: **10 — Ambience**, **05 — Soft cheering I**, **04 — Strong cheering II — Short**. Renamed `stadium_bed.mp3`, `stadium_hype.mp3`, `stadium_goal.mp3`; played at independent gains and looped as appropriate. Attribution is also available in Settings → Audio → Audio credits.
- **Whistles** — **dklon**, [author's release](https://opengameart.org/content/whistles), [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/). Original `whistle_1.wav` through `whistle_4.wav` retained. Referee cues sequence the first recording, with a lower final-blow playback pitch. No source recording was edited.

Licences permit reuse and adaptation; this game does not imply the artists endorse it. The source manifest concerns byte integrity and provenance; subjective listening/mix approval remains a human review.

## Current referee, football and reveal audio

- Referee whistle: Rosa-Orenes256, CC0, https://freesound.org/people/Rosa-Orenes256/sounds/538422/ . Public embedded HQ MP3 preview, https://cdn.freesound.org/previews/538/538422_11966684-hq.mp3 ; replaces the synthetic whistle in runtime.
- Football kick: bittermelonheart, CC0, https://freesound.org/people/bittermelonheart/sounds/555042/ . Public embedded HQ MP3 preview, https://cdn.freesound.org/previews/555/555042_11910076-hq.mp3 . Pass/dribble/shot cues use different gains/pitches; save/tackle also layer the credited Kenney recordings.
- Card handling: Kenney Casino Audio 1.1, CC0, https://kenney.nl/assets/casino-audio . card-shuffle.ogg, card-place-2.ogg, card-slide-1.ogg; original licence included.
- Walkout music: Hyperton by Sudocolon, CC0, https://opengameart.org/content/hyperton . Original Hyperton.mp3 renamed walkout.mp3. The earlier dklon recordings remain as unused source variants; runtime uses the real referee recording above.
Vendored licence text is retained with line endings/trailing whitespace normalized; audio payload bytes are unchanged.

## Arcade presentation — 1 November 2026

Runtime menu music and short interface/card/football effects use original project-authored pulse/triangle/noise synthesis in `arcade/`, reproducible with `tools/make_arcade_audio.gd`. No third-party samples were used in these generated WAV files. Earlier menu/cue recordings remain historical assets; the restored real referee whistle, unchanged crowd and walkout recordings retain the source credits above; earlier football/impact/card recordings remain credited historical variants. Music and effects preferences still control the separate layers.
