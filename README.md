# LepiDreams Engine

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Status](https://img.shields.io/badge/status-WIP-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Made with Love](https://img.shields.io/badge/made%20with-love-red)

**LepiDreams** is a personal study project — a simple 2D game engine built with Flutter.  
It is designed to help me experiment while creating my own games, and to serve as a lightweight toolkit that makes building 2D games easier with some "out of the box" features.  

⚠️ **Important note**: This engine is **not production-ready**.  
It is under active (but irregular) development, maintained only when I have free time. Expect missing features, breaking changes, and incomplete implementations.

---

## 🎥 Demo
*Coming soon – video showcase will be added here.*

---

## ✨ Purpose
- Provide a lightweight and easy-to-use 2D game toolkit for Flutter.  
- Offer some pre-built features to speed up game development.  
- Act as a playground for experimentation and learning game engine design.  

---

## 🌟 Features & Motivation

### My personal motivation
I have been developing games and software for over 20 years. My passion for programming was born from video games — and I’ve always dreamed of creating my own. Over the years I managed to build a few, but one thing never changed: the **experience of making games has always felt painful**.  

- Powerful engines like Unity or Unreal? Amazing features, but incredibly slow to open, build, and run — even on powerful machines.  
- Lightweight engines? Fast, but usually missing essential tools, which makes every step harder than it should be.  

So I decided to create something that I personally enjoy using to make games. An engine where the process feels fluid, fun, and creative — not an endless battle with bad math or missing features.  

That’s the vision behind **LepiDreams**: making 2D game development in Flutter smoother, faster, and more enjoyable.  

The goal is to offer **easy ways to build UI, animations, effects (camera shake, object fade, etc.)** — not everything is ready yet, but that’s the direction.  

You’re welcome to join in. Let’s make 2D game development more accessible, so anyone can bring their most unusual ideas to life in the most amazing way possible.  

---

### Engine highlights
LepiDreams is intentionally designed with some **"ready-to-go" helpers** that simplify the development process.  
These are not meant to cover every possible case, but to give developers a **faster starting point** when prototyping or learning:

- **Scene & Layer System**  
  Out-of-the-box support for scenes (menu, gameplay, game over) with transitions, plus layer separation (background, entities, UI).  
  → Motivation: keep games organized and easy to reason about without boilerplate.

- **Camera with Follow & Parallax**  
  Built-in camera that can follow a target, handle zoom, and support parallax backgrounds.  
  → Motivation: camera handling is usually one of the first “hard” things new devs struggle with — so the engine solves it for you.

- **Collision & Physics Basics**  
  Simple AABB and circle colliders, with optional gravity/velocity/acceleration.  
  → Motivation: enough physics to make most 2D games functional, without forcing a heavy physics engine.

- **Sprite & SpriteSheet Animations**  
  Easy-to-use sprites and animation system.  
  → Motivation: handling frame-based animations should be straightforward, especially for beginners.

- **Built-in Audio Manager**  
  Encapsulated audio system (using audioplayers under the hood) for sounds and music.  
  → Motivation: swap audio backend in the future if needed, while keeping a clean API for game developers.

---

## 🚧 Status
- This engine is a **work in progress**.  
- Many features are missing and the API will likely change frequently.  
- Current progress is tracked through **milestones**.  

---

## 🛠 Roadmap (Milestones)

- ✅ **Milestone 1** – Core game loop  
- ✅ **Milestone 2** – GameObject + Scene system  
- ✅ **Milestone 3** – Basic input (keyboard + touch)  
- ✅ **Milestone 4** – Simple rendering (shapes, text)  
- ✅ **Milestone 5** – Sprites & asset loading  
- ✅ **Milestone 6** – Camera (zoom, follow, parallax)  
- ✅ **Milestone 7** – Basic collisions (AABB & circle)  
- ✅ **Milestone 8** – Simple physics (velocity, acceleration, gravity)  
- ✅ **Milestone 9** – Advanced scene management (layers, push/pop/replace)  
- ✅ **Milestone 10** – Audio support  
- ⏳ Future – More utilities, polish, and debugging tools  

---

## 🤝 Contributing
This is a **personal project**, so development speed depends on my availability.  
However, contributions are welcome:  
- Feel free to open issues.  
- Pull Requests are accepted, but reviews might be slow.  

---

## 📜 License
This project is licensed under the terms of the [MIT License](LICENSE.md).  

---
