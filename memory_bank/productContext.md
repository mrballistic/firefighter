# Product Context

## Core loop
1. A victim jumps from one of 5 windows (small hop, 50–80 px/s sideways).
2. The player slides the net under them with the crank.
3. A catch launches them at a fixed speed (280 px/s, about 98 px high and 1.4 s in the air); the hit position sets the angle:
   - centre (h = 0): 5° from vertical, a safe "hold" that inches forward
   - right edge (h = +1): 20°, a long throw toward the ambulance
   - left edge (h = −1): −10°, back toward the building (which bounces them back)
4. Reaching the ambulance scores 100 points, or 150 for an **Express** rescue in 2 bounces or fewer.
5. A victim hitting the ground costs a life. Three lives.

## Difficulty
- Victims at once: 1, then 2 at 500 points, then 3 at 2,000.
- Every 500 points: game time runs 5% faster (capped at 1.4×), and the gap between extra jumpers drops 0.25 s (from 3 s down to 1.5 s).
- Time scaling keeps trajectories identical, so tested reachability holds at any speed.

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
- Is 3 victims at 2,000 too hard? A scripted near-perfect player was down to 1 life after 3 minutes.
- Title is **Crank & Catch**, bundle ID `com.mrballistic.crankandcatch`.
