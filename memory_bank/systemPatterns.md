# System Patterns: Fire Game & Watch Remake

## Architecture Overview

### Component Structure
```
Game Core
├── Game Loop
│   ├── Input Processing (Crank)
│   ├── Physics Update
│   ├── Game State Update
│   └── Render
└── Entity System
    ├── Static Entities (Building, Ambulance)
    ├── Dynamic Entities (Victims, Firefighters)
    └── UI Elements (Score, Lives)
```

## Design Patterns

### Entity Component System
- Entities: Building, Victims, Firefighters, Ambulance
- Components: Position, Collision, Sprite, Physics
- Systems: Movement, Collision, Rendering, Scoring

### State Management
- Game States: Menu, Playing, Paused, GameOver
- Entity States: Spawning, Falling, Bouncing, Rescued, Lost

### Observer Pattern
- Score updates
- Life loss events
- Game over conditions
- High score achievements

### Command Pattern (Input Handling)
- Crank position translation
- Button input processing
- Menu navigation

## Key Technical Patterns

### Physics System
- Simple gravity simulation
- Bounce mechanics
- Collision detection optimization
- Position clamping for boundaries

### Rendering Pipeline
1. Background elements
2. Static game objects
3. Dynamic entities
4. UI overlay
5. Effects/particles

### Resource Management
- Sprite caching
- Sound pooling
- Memory optimization
- Asset preloading

## Code Organization

### Directory Structure
```
source/
├── main.lua           # Entry point
├── game/
│   ├── entities/      # Game objects
│   ├── physics/       # Physics system
│   ├── ui/           # User interface
│   └── states/       # Game states
└── assets/           # Resources
```

### File Naming Conventions
- Modules: lowercase with underscores
- Classes: PascalCase
- Constants: UPPERCASE_WITH_UNDERSCORES

## Testing Patterns
- Unit tests for physics calculations
- Integration tests for game states
- Performance benchmarking
- Input validation testing

## Error Handling
- Graceful degradation
- State recovery
- Input validation
- Resource loading fallbacks

## Performance Patterns
- Sprite batching
- Collision optimization
- Memory pooling
- Frame rate stabilization
