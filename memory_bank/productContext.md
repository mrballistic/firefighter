# Product Context

## Core loop
1. A victim jumps from one of 5 windows (small hop, 50–80 px/s sideways).
2. The player slides the net under them with the crank.
3. A catch launches them at a fixed speed (280 px/s, about 98 px high and 1.4 s in the air); the hit position sets the angle:
   - center (h = 0): 5° from vertical, a safe "hold" that inches forward
   - right edge (h = +1): 20°, a long throw toward the ambulance
   - left edge (h = −1): −10°, back toward the building (which bounces them back)
4. Reaching the ambulance scores 100 points, or 150 for an **Express** rescue in 2 bounces or fewer.
5. A victim hitting the ground costs a life. Three lives.

## Difficulty
- **Net width** (`Rules.netWidth`): 72 px at the start, −4 px every 500 points, floor 44 px at 3,500. Narrowing animates (24 px/s) with a "NET NARROWS" popup. Hit position is relative to the current width, so aim means the same at every width; the net image is composed per width from the art's two end figures (5 px each, all walk frames) plus a drawn net and aim marks.
- **Extra life** every 10,000 points, capped at 5 lives, with an "EXTRA LIFE!" popup and chime.
- Victims at once: 1, then 2 at 500 points, then 3 at 2,000.
- Every 500 points: game time runs 5% faster (capped at 1.3×, reached at 3,000), and the gap between extra jumpers drops 0.25 s (from 3 s down to 1.5 s).
- Time scaling keeps trajectories identical, so tested reachability holds at any speed.
- **Fair spawning** (`Rules.chooseLaunch`): an extra jumper leaps only if its first landing and every other jumper's next landing are reachable at 300 px/s of crank travel plus 0.2 s of reaction time (scaled by game speed); otherwise it waits a frame and retries. Measured with `scripts/fairness.lua` at 300 px/s: the two-jumper stage went from 8.4 misses/min (68% unavoidable) to 1.2/min (0%); the three-jumper stage from 18.1/min to 3.6/min (about 1/min still unavoidable, all from clashes after the first bounce). More slack made it worse, so 300/0.2 stays.

## Menu
- The title is cropped from the launcher card (`scripts/make_title.py`).
- **Attract mode:** the real scene plays behind the title. A demo player walks to each jumper's predicted landing point and aims at random between 0.2 and 0.9, so it shows short and long throws. It's silent and never scores. Demo jumpers use only the lower two windows, so their arcs stay below the menu text.
- A blinking "Press Ⓐ to Start", then one line rotating through the high score and three hints.
- Every UI text line has a black backing box (also in game, for the HUD and overlays).

## Feel and feedback
- Net sags 3 px on a catch; the bounce pitch rises with hit position, so players can hear their aim.
- Score popups ("+100", "EXPRESS +150", "MISS"), screen shake on a miss, ambulance flash on a rescue.
- Opening the Playdate menu auto-pauses.

## Known open questions
- How the busy stages feel on hardware now that spawning is fair.
- Endgame (3,500+: 44 px net, 1.3×, three jumpers): softened from 40 px / 1.4×. Fairness probe at 300 px/s: 9.7 → 6.0 misses/min, unavoidable 49% → 30%; at 450 px/s, 0.6 misses/min. Still the hardest stretch at a relaxed pace; extra lives help.
- Title is **Crank & Catch**, bundle ID `com.mrballistic.crankandcatch`.
