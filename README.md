# 🚒 Fire Game & Watch Remake

A modern remake of the classic Game & Watch Fire game for the Playdate console. Save victims from a burning building in this physics-based action game! 🎮

## ✨ Features

- 🎯 Physics-based gameplay with dynamic bounce mechanics
- 🌟 Edge-based bouncing system for strategic play
- 📈 Progressive difficulty scaling
- 🎨 Classic black and white aesthetic
- 🎪 Crank-based controls
- 🏆 High score tracking

## 🎮 Gameplay

Help rescue victims from a burning building:
1. 🎪 Use the crank to move firefighters left and right
2. 🛟 Catch falling victims with the trampoline
3. 🚑 Bounce them toward the ambulance
4. ⭐ Score increases with each successful rescue
5. ❌ Game ends when you lose all lives

### 🕹️ Controls
- **🎪 Crank**: Move firefighters left/right
- **🅰️ A Button**: Start game / Menu selection
- **🅱️ B Button**: Pause/Resume game

### ⚙️ Mechanics
- 💫 Edge hits provide stronger horizontal momentum
- ⚡ Minimum bounce velocity ensures ambulance reach
- 📈 Progressive difficulty (second victim at 500 points)
- 🔄 Immediate victim respawn after rescue/loss

## 🛠️ Development

### 📋 Requirements
- 🎮 Playdate SDK
- 🌙 Lua development environment
- 💻 VSCode (recommended)

### 🚀 Setup
1. 📥 Clone the repository
2. ⚙️ Install Playdate SDK
3. 📂 Open in VSCode
4. 🎮 Build and run using Playdate simulator

### 📁 Project Structure
```
source/
├── main.lua           # Game loop and state management
├── game/
│   ├── entities/      # Game objects
│   │   ├── building.lua
│   │   ├── firefighters.lua
│   │   ├── ambulance.lua
│   │   └── victim.lua
│   ├── physics/       # Physics calculations
│   ├── states/       # Game state handling
│   └── ui/           # User interface elements
└── assets/           # Game resources
```

### 🏗️ Building
```bash
# Build PDX file
pdc source Fire.pdx

# Run in simulator
playdate-simulator Fire.pdx
```

## 🔧 Technical Details

### ⚡ Physics System
- 🌍 Gravity: 200 pixels/second squared
- 💫 Edge-based bounce calculations
- ⚖️ Momentum preservation
- 📏 Position clamping

### ⚙️ Game Configuration
```lua
-- Core settings
FPS = 30
PHYSICS_STEP = 1/30
VICTIM_SPAWN_INTERVAL = 3
SCORE_PER_RESCUE = 100
VICTIMS_INCREASE_THRESHOLD = 500

-- Physics constants
BOUNCE_DAMPING = 0.8
HORIZONTAL_DAMPING = 0.95
MIN_HORIZONTAL_SPEED = 50
RIGHT_BIAS = 30
```

### 🔄 State Management
- 📋 Menu
- 🎮 Playing
- ⏸️ Paused
- 🏁 Game Over

## 🤝 Contributing

1. 🔱 Fork the repository
2. 🌿 Create your feature branch
3. 💾 Commit your changes
4. 🚀 Push to the branch
5. 📬 Create a Pull Request

## 🎯 Planned Features

- [ ] 🔊 Sound effects
- [ ] ✨ Particle effects
- [ ] 💫 Visual feedback
- [ ] 🔄 Menu transitions
- [ ] 📖 Instructions screen
- [ ] 📊 Statistics tracking

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
