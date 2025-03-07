# Technical Context: Fire Game & Watch Remake

## Development Environment

### Platform
- Playdate SDK
- Lua programming language
- VSCode with Lua extensions
- Git version control

### Build System
- PDX compilation
- Source directory structure
- Asset management
- Version control with .gitignore

## Core Systems

### Game Loop
```lua
function playdate.update()
    -- Clear and set background
    gfx.clear()
    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.setColor(gfx.kColorWhite)
    
    -- Update game state
    handleInput()
    updatePhysics(dt)
    updateEntities()
    
    -- Draw UI
    drawUI()
end
```

### Physics System
- Gravity: 200 pixels/second squared
- Delta time-based updates
- Velocity and position management
- Collision detection and response

### Input Handling
```lua
-- Crank movement
local CRANK_SENSITIVITY = 2.0
local MIN_X = 80  -- Left boundary
local MAX_X = 350 -- Right boundary

function updatePosition()
    local change = playdate.getCrankChange()
    local newX = x + (change * CRANK_SENSITIVITY)
    newX = math.max(MIN_X, math.min(MAX_X, newX))
    self:moveTo(newX, y)
end
```

### Bounce Physics
```lua
-- Edge-based bounce calculation
local MIN_BOUNCE_VELOCITY = 200
local HORIZONTAL_BOOST = 30
local EDGE_BOOST = 40

-- Calculate hit position (-1 to 1)
local hitPosition = (x - center) / (width/2)
local edgeBoost = math.abs(hitPosition) * EDGE_BOOST

-- Apply velocities
local newVx = math.max(vx * 0.5, 0) + HORIZONTAL_BOOST + edgeBoost
local newVy = -math.max(math.abs(vy), MIN_BOUNCE_VELOCITY)
```

## Entity Management

### Sprite System
```lua
-- Sprite cleanup
function initGame()
    gfx.sprite.removeAll()  -- Clear all sprites
    createEntities()        -- Create fresh entities
end

-- Entity creation
local image = gfx.image.new(width, height)
gfx.pushContext(image)
    gfx.setColor(gfx.kColorWhite)
    -- Draw entity
gfx.popContext()
```

### State Management
```lua
local GameState = {
    MENU = "menu",
    PLAYING = "playing",
    PAUSED = "paused",
    GAME_OVER = "gameOver"
}

-- State transitions
if gameState.lives <= 0 then
    gameState.currentState = GameState.GAME_OVER
end
```

## Memory Management

### Resource Handling
- Sprite cleanup between states
- Image caching
- Entity pooling
- State-based resource allocation

### Performance Optimization
- Minimal object creation
- Efficient collision checks
- Sprite batching
- Clean state transitions

## Configuration

### Game Settings
```lua
local Config = {
    FPS = 30,
    PHYSICS_STEP = 1/30,
    VICTIM_SPAWN_INTERVAL = 3,
    SCORE_PER_RESCUE = 100,
    VICTIMS_INCREASE_THRESHOLD = 500,
    INITIAL_HORIZONTAL_VELOCITY = 100
}
```

### Physics Constants
```lua
local BOUNCE_DAMPING = 0.8
local HORIZONTAL_DAMPING = 0.95
local MIN_HORIZONTAL_SPEED = 50
local RIGHT_BIAS = 30
```

## Technical Debt

### Current Issues
- None reported

### Future Improvements
1. Sound System Integration
   - Effect triggers
   - Sound pooling
   - Volume management

2. Visual Effects
   - Particle system
   - Animation system
   - Transition effects

3. Performance Optimization
   - Sprite batching
   - Collision optimization
   - Memory management

4. Menu System
   - Smooth transitions
   - Instructions screen
   - Settings menu

## Testing Strategy

### Unit Testing
- Physics calculations
- Collision detection
- State transitions

### Integration Testing
- Game flow
- Entity interactions
- State management

### Performance Testing
- Frame rate monitoring
- Memory usage
- Sprite count impact

## Version Control

### Git Configuration
```gitignore
# Playdate compiled files
**/*.pdx/
**/*.pdz
**/..pdx/
source/**/Fire.pdx/

# Build artifacts
build/
dist/

# Development files
.vscode/
*.log
```

### Build Process
1. Compile Lua files
2. Package assets
3. Generate PDX
4. Deploy to simulator/device
