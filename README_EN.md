# Letter Drop Animation

[中文](README.md) | English

A cyberpunk-style letter drop animation application based on Flutter and Flame Forge2D physics engine.

## Project Description

This application showcases a letter drop animation with physics effects, where letters are randomly generated from the top of the screen and fall down, following physical rules to collide with boundaries and other letters. Each letter has cyberpunk-style visual effects, including neon colors, glow effects, and glitch art style.

## Features

- Physics engine-based realistic falling animation
- Cyberpunk-style visual design
  - Neon colors (Quantum Blue, Glitch Purple, Signal Green)
  - Glow and shadow effects
  - Glitch art style visual presentation
- Vowel letters have greater mass
- Physical collision between letters and boundaries and other letters
- Collision sound effects
- Periodic automatic generation of new letters

## Tech Stack

- Flutter framework
- Flame game engine
- Forge2D physics engine (Dart implementation of Box2D)
- Flutter Riverpod state management
- Google Fonts
- AudioPlayers for audio playback

## Installation and Running

1. Make sure Flutter SDK and related dependencies are installed
2. Clone this repository
3. Run the following command to install dependencies:

```bash
flutter pub get
```

4. Run the application:

```bash
flutter run
```

## Project Structure

- `main.dart` - Application entry point, contains UI setup and game world initialization
- `letter_physics.dart` - Implementation of letter physics bodies, including visual effects and physical properties

## Customization

You can customize the animation effects by modifying the following parameters:

- Modify the color list `cyberpunkColors` in the `LetterBody` class
- Adjust the generation interval in the `_startLetterGeneration` method
- Modify physical properties (density, friction, elasticity, etc.) in `LetterBody.createBody`

## License

This project is licensed under the MIT License. See the LICENSE file for details.