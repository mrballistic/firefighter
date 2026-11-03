# Project Brief

## What it is
An original crank-controlled rescue game for Playdate called **Crank & Catch**. People jump from a burning building; the player slides a net under them and bounces them across the screen into an ambulance.

It shares the catch-and-bounce idea common to the genre, but it is its own game: physics-driven, with aiming by hit position, and with its own art, title and presentation. It is not a recreation of any specific existing game. Keep it that way: no borrowed names, characters, layouts or LCD-style look.

## Core requirements
- Crank moves the net (D-pad fallback).
- **Where a victim lands on the net sets the bounce angle.** That is the central skill.
- Scoring, lives, difficulty ramp, persistent high score.
- 1-bit visuals and sound feedback.

## Platform
Playdate: 400×240 1-bit display, crank, Lua 5.4 via the Playdate SDK (developed on 3.1.2).

## Success criteria
- Steady 30 fps; responsive crank.
- Every jumper is catchable, and every throw can reach the ambulance (enforced by tests).
- Aiming matters: each step of aim toward the right edge saves bounces (tuned with `scripts/tune.lua`).
