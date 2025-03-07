# Technical Context: Fire Game & Watch Remake

## Development Environment

### Platform
- Target: Playdate handheld console
- Screen: 400x240 1-bit display
- Controls: Crank (primary), D-pad and buttons (secondary)
- CPU: 168 MHz ARM processor
- Memory: 16MB RAM

### Development Tools
- Language: Lua
- SDK: Playdate SDK
- IDE: Visual Studio Code
- Platform: macOS
- Version Control: Git

### Required Extensions
- Playdate VSCode extension
- Lua language support
- Lua formatter

## Technical Stack

### Core Technologies
- Lua programming language
- Playdate SDK
- Built-in physics engine
- Sprite management system
- Sound engine

### Development Dependencies
- Playdate Simulator
- Lua debugger
- Performance profiling tools
- Asset creation tools

## Technical Constraints

### Hardware Limitations
- 1-bit display (black and white only)
- Limited RAM (16MB)
- CPU speed considerations
- Battery life optimization

### Performance Requirements
- 30 FPS minimum
- Responsive crank input (<16ms latency)
- Efficient collision detection
- Memory-conscious asset management

### Technical Boundaries
- Maximum sprite count considerations
- Audio channel limitations
- Storage space constraints
- Power consumption guidelines

## Development Standards

### Code Style
- Lua style guide compliance
- Clear function and variable naming
- Comprehensive inline documentation
- Modular code organization

### Asset Requirements
- 1-bit sprite art
- Optimized sound files
- Efficient resource loading
- Memory-conscious asset management

### Testing Requirements
- Unit testing framework
- Performance benchmarking
- Playdate simulator testing
- Hardware testing

## Build and Deployment

### Build Process
1. Lua code compilation
2. Asset bundling
3. Resource optimization
4. Package creation

### Deployment Steps
1. Simulator testing
2. Hardware verification
3. Performance validation
4. Package distribution

## Monitoring and Maintenance

### Performance Metrics
- Frame rate monitoring
- Memory usage tracking
- Input latency measurement
- Battery impact assessment

### Debug Tools
- Console logging
- Performance profiler
- Memory analyzer
- Frame timing tools

## Security Considerations

### Data Storage
- Local high score persistence
- Save state management
- Data corruption prevention
- Safe file operations

### Input Validation
- Crank position bounds
- Game state validation
- Resource integrity checks
- Error recovery procedures
