# Active Context: Fire Game & Watch Remake

## Current Focus
Gameplay refinement and physics tuning. Polishing core mechanics and game flow.

## Recent Changes
- Improved bounce physics
  - Edge-based bouncing for more dynamic gameplay
  - Stronger horizontal momentum on edge hits
  - Minimum bounce velocity to ensure ambulance reach
- Enhanced victim spawning
  - Immediate spawn after death or rescue
  - Progressive difficulty (1-2 victims)
  - Proper spawn timing and management
- Visual and layout improvements
  - Proper sprite cleanup between states
  - Consistent white-on-black visuals
  - Clear UI text rendering
- Game flow enhancements
  - Clean state transitions
  - Better sprite management
  - Proper game reset handling

## Active Decisions

### Architecture Decisions
1. Observer pattern for game events
2. State-based game flow
3. Physics-based gameplay
4. Modular entity system

### Technical Decisions
1. Dynamic bounce physics based on hit position
2. Progressive difficulty scaling
3. Immediate victim respawning
4. Clean sprite management

## Current Considerations

### Implementation Priorities
1. Sound effects and feedback
2. Visual polish (particles, animations)
3. Additional gameplay features
4. Menu system enhancements
5. High score persistence

### Technical Challenges
1. Fine-tuning bounce physics
2. Balancing difficulty progression
3. Optimizing sprite management
4. Smooth state transitions
5. Performance optimization

## Next Steps

### Immediate Tasks
1. Add sound effects for:
   - Victim bouncing
   - Successful rescue
   - Game over
2. Add visual feedback:
   - Bounce effects
   - Rescue celebration
   - Score indicators
3. Enhance menu system:
   - Better transitions
   - Visual polish
   - Instructions screen

### Upcoming Work
1. Additional gameplay features
2. Performance optimization
3. Asset refinement
4. Testing and balancing
5. Polish and feedback

## Open Questions
1. Additional gameplay mechanics
2. Scoring system refinements
3. Visual effect improvements
4. Sound design approach

## Risk Assessment

### Technical Risks
1. Physics edge cases
2. Performance with multiple victims
3. Memory management
4. State transition bugs

### Mitigation Strategies
1. Comprehensive testing
2. Performance monitoring
3. Clean state management
4. Robust error handling
