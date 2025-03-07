# 🔥 Fire - A Game & Watch Remake for Playdate 🎮

A modern remake of Nintendo's classic Game & Watch "Fire" game, adapted specifically for the Playdate handheld gaming system. This version utilizes Playdate's unique crank control mechanism to deliver a fresh take on the classic gameplay.

## 📖 Description

In this game, you control firefighters with a trampoline trying to save people jumping from a burning building. Using the Playdate's crank mechanism, you move the firefighters left and right to catch jumpers and bounce them safely into a waiting ambulance.

## ✨ Features

- 🎯 Crank-controlled firefighter movement
- 🦘 Physics-based jumping and bouncing mechanics
- 📊 Score tracking system
- 📈 Progressive difficulty
- 🎨 Classic 1-bit graphics optimized for Playdate
- 🕹️ Authentic Game & Watch style gameplay

## 🛠️ Development Setup

### 📋 Prerequisites

1. 🎮 [Playdate SDK](https://play.date/dev/)
2. 💻 Visual Studio Code
3. 🌙 Lua language support

### 🔧 Installation

1. Clone this repository
2. Install the Playdate SDK
3. Install required VS Code extensions:
   - Lua by sumneko
   - Lua Format by Koihik

### 🚀 Running the Game

From the project root:

```bash
cd source
pdc -v . Fire.pdx
open -a "Playdate Simulator" Fire.pdx
```

### 🎮 Controls

- **Crank**: Move firefighters left/right
- In simulator: Hold Shift + mouse movement to simulate crank

## 📁 Project Structure

```
source/
├── main.lua           # Entry point
├── game/
│   ├── entities/      # Game objects
│   │   ├── firefighters.lua
│   │   ├── building.lua
│   │   └── ambulance.lua
│   ├── physics/       # Physics system
│   ├── ui/           # User interface
│   └── states/       # Game states
└── assets/           # Resources
```

## 💻 Development

- All game entities use the Entity Component System pattern
- Physics calculations are optimized for Playdate's hardware
- Memory management is carefully considered for the 16MB RAM constraint
- 1-bit display optimization for clear visuals

## 🤝 Contributing

1. 🔄 Fork the repository
2. 🌿 Create your feature branch
3. 💾 Commit your changes
4. ⬆️ Push to the branch
5. 📬 Create a new Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## 🙏 Acknowledgments

- 🎮 Original Game & Watch "Fire" game by Nintendo
- 🌟 Playdate by Panic
- 👥 All contributors to this project
