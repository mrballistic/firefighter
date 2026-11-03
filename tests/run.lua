-- Run every test file. From the repo root:  lua tests/run.lua
-- No Playdate SDK needed: these cover the pure-Lua modules (config, physics,
-- rules). The Playdate runs Lua 5.4; keep those modules to the subset shared
-- with whatever `lua` you have locally.
dofile("tests/harness.lua")
dofile("source/game/config.lua")
dofile("source/game/physics.lua")
dofile("source/game/rules.lua")
dofile("tests/physics_test.lua")
dofile("tests/rules_test.lua")
T.finish()
