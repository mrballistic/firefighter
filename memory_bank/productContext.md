# Product Context: Fire Game & Watch Remake

## Game Overview

### Core Concept
A modern remake of the classic Game & Watch Fire game, featuring:
- Physics-based gameplay
- Dynamic bounce mechanics
- Progressive difficulty
- Classic black and white aesthetic

### Target Platform
- Playdate handheld console
- 400x240 1-bit display
- Crank-based control system

## Gameplay Mechanics

### Core Loop
1. Victims fall from building windows
2. Player moves firefighters with crank
3. Catch victims with trampoline
4. Bounce victims toward ambulance
5. Score points for successful rescues

### Movement System
- Crank-based horizontal movement
- Bounded play area (x: 80-350)
- Smooth position updates
- Precise control for catching

### Physics System
- Gravity-based falling
- Dynamic bounce mechanics
- Edge-based bounce angles
- Momentum preservation

## Game Elements

### Building
- Multiple spawn windows
- Left side of screen
- Visual reference point
- Spawn point management

### Firefighters
- Crank-controlled movement
- Trampoline mechanics
- Edge-based bouncing
- Position constraints

### Victims
- Physics-based movement
- Bounce mechanics
- State management
- Progressive spawning

### Ambulance
- Rescue zone
- Right side position
- Visual feedback
- Score trigger

## Progression System

### Difficulty Scaling
1. Start with single victim
2. Unlock second victim at 500 points
3. Immediate respawn after rescue/loss
4. Increased challenge through speed

### Scoring System
- 100 points per rescue
- High score tracking
- Progressive unlocks
- Performance feedback

## Game States

### Menu State
- Title display
- Start prompt
- High score display
- Clean transitions

### Playing State
- Active gameplay
- Score display
- Lives counter
- Dynamic spawning

### Paused State
- Game suspension
- Resume option
- State preservation
- Clear UI

### Game Over State
- Final score
- Return to menu
- High score update
- Clean reset

## Visual Design

### Aesthetic
- Classic Game & Watch style
- Black and white graphics
- Clear visual hierarchy
- High contrast elements

### UI Elements
- Score counter (top left)
- Lives display (top right)
- Menu text (centered)
- State indicators

## Player Experience

### Core Engagement
- Skill-based gameplay
- Risk/reward decisions
- Progressive challenge
- Score motivation

### Control Feel
- Precise crank movement
- Responsive bouncing
- Predictable physics
- Clear feedback

### Learning Curve
1. Basic movement
2. Timing catches
3. Edge bounce mechanics
4. Multiple victim management

## Future Enhancements

### Planned Features
1. Sound Effects
   - Bounce impacts
   - Rescue success
   - Game over
   - Menu selection

2. Visual Polish
   - Particle effects
   - Animation frames
   - Menu transitions
   - Rescue celebration

3. Gameplay Additions
   - Bonus scoring
   - Special events
   - Achievement system
   - Challenge modes

4. UI Improvements
   - Instructions screen
   - Settings menu
   - Statistics tracking
   - Visual feedback

## Quality Standards

### Performance
- Consistent 30 FPS
- Responsive controls
- Clean state transitions
- Efficient resource use

### Polish
- Clear visual feedback
- Smooth animations
- Intuitive controls
- Clean UI

### Stability
- Proper state management
- Memory cleanup
- Error handling
- Save data handling
