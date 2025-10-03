## LepiDreams Engine — Release Notes

Version: 0.1.0+2
Date: 2025-10-03

### Highlights

- Animation System
  - Built-in tweens (move, scale, rotate, fade, color)
  - Effects (shake, pulse, blink, wiggle)
  - Path following and custom animations groundwork

- SpriteSheetBuilder
  - Generate static sprite sheets more easily -> `buildWithCollider` to create sprites already configured with colliders

- Viewport & Camera
  - Viewport system added
  - Camera follow improvements and sprite sheet flip corrections

- GameObject utilities
  - `attach` support to bind objects
  - `rotateToObject` to rotate an object towards a target

- Collisions & Physics
  - Side-aware collision detection; fixes for collision while rotating
  - Physics updated to work with nested components

### Fixes and Improvements

- Layer sorting fix
- Rotation and initialization fixes across scenes
- Keyboard beep sound fix
- Documentation and milestone updates

### Playground, Examples & Tools

- New Ships Battle example
  - Minimum AI, bullet collision, bullet water effect
  - Light damage shake effect

- Platform Game example
  - Minor fixes and improvements

- Tilemap Editor (WIP) available in the playground

### Known Issues

- Hot Reload does not work during development; use Restart
- Sequential/parallel animations may duplicate and behave incorrectly
- Scene does not start at position (0,0); needs repositioning at game start

### Project Status

- Work in progress (WIP). The API and behavior may change between versions

