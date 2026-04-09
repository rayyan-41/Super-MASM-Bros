# 🍄 Super MASM Bros

A Super Mario Bros-inspired console game written entirely in **x86 MASM (Microsoft Macro Assembler)**. Developed as a COAL (Computer Organization and Assembly Language) course project — Fall 2025.

Navigate Mario through three platformer screens per world, collect coins, stomp Goombas, shoot fireballs, and rescue the princess — all rendered in the Windows console using low-level Win32 API calls.

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Setup & Build](#setup--build)
- [Running the Game](#running-the-game)
- [Controls](#controls)
- [Gameplay](#gameplay)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Features

| Feature | Description |
|---|---|
| **Main Menu** | Animated title, 5-option menu (Begin Game, Leaderboard, Settings, Instructions, Exit) |
| **3 Screens × 2 Worlds** | World 1-1, 1-2, 1-3 (Snow), World 2-1 (Boss) |
| **Physics** | Gravity, jumping, collision detection |
| **Enemies** | Up to 10 active Goombas per screen; stomp or shoot them |
| **Coins** | Collect `o` tokens to score points; +10,000 bonus for rescuing the princess |
| **Fireballs** | Shoot projectiles with `S` to defeat enemies at range |
| **Snow Weather** | Falling snowflakes on the World 1-3 (Snow) screen |
| **Hell Mode** | Inverts the full colour palette for a challenge |
| **Fly Mode** | Disables gravity — move freely in all directions |
| **Background Music** | Per-screen WAV music via Windows Multimedia API |
| **Sound Effects** | Coin collect, jump, game-start, and more |
| **Settings Screen** | Toggle background music on/off |
| **Dynamic Palette** | Animated colour cycling on the menu title |

---

## Prerequisites

| Requirement | Notes |
|---|---|
| **Windows 10/11** | Win32 API is used throughout; Linux/macOS are not supported |
| **Visual Studio 2019 or 2022** | Requires the **Desktop development with C++** workload (includes ML.exe / MASM) |
| **Irvine32 Library** | Must be installed at `C:\DevTools\irvine` (path is hard-coded in the project) |
| **Windows SDK 10.0** | Included with the Visual Studio C++ workload |

### Installing Irvine32

1. Download the Irvine32 package from the [Kip Irvine textbook website](http://www.asmirvine.com/) or your course materials.
2. Extract the files so that `Irvine32.inc`, `Irvine32.lib`, and related headers are located in `C:\DevTools\irvine\`.
3. No additional environment variables are needed — the path is referenced directly in `Mario.vcxproj`.

> **Tip:** If you prefer a different installation path, update the `<AdditionalLibraryDirectories>` and `<IncludePaths>` entries inside `Mario/Mario.vcxproj` before building.

---

## Project Structure

```
Super-MASM-Bros/
├── FINAL_PROJECT.slnx          # Visual Studio solution (open this to build)
└── Mario/
    ├── main.asm                 # Entire game source (~60 KB of x86 MASM)
    ├── Mario.vcxproj            # Visual Studio project file
    ├── Mario.vcxproj.filters    # IDE file groupings
    ├── highscore.txt            # Persistent high-score storage (auto-created on first run)
    ├── coin.wav                 # Coin-collect sound effect
    ├── funny.wav                # Funny mode sound effect
    ├── lvl1.wav                 # Level 1 background music
    ├── menu.wav                 # Main-menu background music
    ├── start.wav                # Game-start fanfare
    └── start_mario.wav          # Mario theme intro
```

> **Note:** `scary.wav` and `scarylevel.wav` are referenced in the source code but are not bundled in the repository. The game handles their absence gracefully (sounds simply do not play).

---

## Setup & Build

### 1. Clone the repository

```bash
git clone https://github.com/rayyan-41/Super-MASM-Bros.git
cd Super-MASM-Bros
```

### 2. Open in Visual Studio

Double-click `FINAL_PROJECT.slnx`, or open Visual Studio and choose **File → Open → Project/Solution**, then select `FINAL_PROJECT.slnx`.

### 3. Verify the build configuration

In the Visual Studio toolbar, select:
- **Configuration:** `Debug`
- **Platform:** `Win32` *(recommended — the Irvine32 library is 32-bit)*

### 4. Build

Press **Ctrl+Shift+B** (or **Build → Build Solution**).

A successful build produces `Mario.exe` inside `Mario\Debug\` (or `Mario\Release\` for a Release build).

### 5. Copy audio assets

The executable looks for `.wav` files **in its working directory**. Copy all `.wav` files from `Mario/` into `Mario/Debug/` before running:

```
Mario/Debug/
├── Mario.exe
├── coin.wav
├── funny.wav
├── lvl1.wav
├── menu.wav
├── start.wav
└── start_mario.wav
```

> Visual Studio's default working directory when running with **F5** or **Ctrl+F5** is the project folder (`Mario/`), so the sounds should work out-of-the-box when launched from the IDE.

---

## Running the Game

### From Visual Studio (recommended)

Press **Ctrl+F5** (Start Without Debugging). The Windows console window opens and the main menu appears immediately.

### From the command line

```cmd
cd Mario\Debug
Mario.exe
```

---

## Controls

### Menu Navigation

| Key | Action |
|---|---|
| `↑` / `↓` | Move cursor up/down through menu options |
| `Enter` | Select highlighted option |

### In-Game

| Key | Action |
|---|---|
| `A` / `←` | Move left |
| `D` / `→` | Move right |
| `W` / `↑` / `Space` | Jump |
| `S` | Shoot fireball (normal mode) |
| `P` | Pause / unpause |
| `I` | Toggle **Hell Mode** (inverts colour palette) |
| `T` | Toggle **Fly Mode** (disables gravity) |
| `F` | Play funny sound effect |
| `Escape` | Return to main menu |

### Fly Mode Controls

| Key | Action |
|---|---|
| `W` | Fly up |
| `S` | Fly down |

### Pause Menu

| Key | Action |
|---|---|
| `1` | Continue game |
| `2` | Return to main menu |

---

## Gameplay

### Objective

Guide Mario from the left side of the level to the **flag (`F`)** at the far right of Screen 3 to complete the world. Defeat or avoid Goombas (`G`) along the way and collect as many coins (`o`) as possible.

### Level Progression

```
World 1-1  (Screen 1)
    ↓  reach right edge
World 1-2  (Screen 2)
    ↓  reach right edge
World 1-3  (Screen 3, Snow)  →  reach the flag
    ↓  boss transition cutscene
World 2-1  (Boss Level, Screen 1)
    ↓  defeat the boss
        🎉 PRINCESS SAVED! (+10,000 bonus points)
```

### Scoring

| Event | Points |
|---|---|
| Collect a coin (`o`) | +1 per coin |
| Stomp a Goomba | Score updated |
| Shoot a Goomba | Score updated |
| Rescue the princess | +10,000 bonus |

Your final score and name are appended to `highscore.txt` at the end of the game and viewable from the **Leaderboard** screen.

### Level Map Legend

| Symbol | Meaning |
|---|---|
| `X` | Ground / solid terrain |
| `P` | Pipe (solid) |
| `B` | Brick platform |
| `Q` | Question block |
| `S` | Slope terrain |
| `C` / `c` | Cloud decoration |
| `H` | Underground/tunnel tile |
| `T` | Tree |
| `o` | Coin (collectible) |
| `G` | Goomba (enemy) |
| `F` | Finish flag |
| `M` | Mario start position |

---

## Troubleshooting

### No sound / music

- Make sure all `.wav` files are in the **same directory as `Mario.exe`**.
- Check that your system audio is not muted.
- If running from the IDE, verify that the **Working Directory** in project properties points to the `Mario/` folder (this is the default).

### Build error: `Cannot open include file: 'Irvine32.inc'`

The Irvine32 library is not found at `C:\DevTools\irvine`. Either:
1. Install Irvine32 to `C:\DevTools\irvine\`, **or**
2. Edit `Mario/Mario.vcxproj` and update the `<IncludePaths>` and `<AdditionalLibraryDirectories>` elements to point to your actual installation directory.

### Build error: `LNK1181: cannot open input file 'Irvine32.lib'`

Same cause as above — the linker cannot find `Irvine32.lib`. See the fix directly above.

### Game window is too small / text is clipped

The game is designed for a console window at least **120 columns wide and 30 rows tall**. Right-click the console title bar → **Properties** → **Layout** and increase the window/buffer size.

### `highscore.txt` is not created

On first run the game creates `highscore.txt` in its working directory. If you see a permissions error, ensure the executable has write access to its working directory (avoid placing it in `C:\Program Files\`).

### Game runs very fast or very slow

The game loop is timed at approximately 60 ms per tick using `GetMseconds` from the Irvine32 library. Performance anomalies may occur on very fast/slow CPUs. No fix is currently implemented.

---

## Contributing

Contributions are welcome! To contribute:

1. **Fork** this repository.
2. Create a new branch for your feature or fix:
   ```bash
   git checkout -b feature/my-improvement
   ```
3. Make your changes in `Mario/main.asm` (or project files as needed).
4. Test the build and gameplay thoroughly on Windows.
5. Open a **Pull Request** describing your changes.

### Guidelines

- Keep changes scoped and well-commented in the assembly source.
- Follow the existing code style: group related procedures together, use consistent label naming (PascalCase for procedures, UPPER_CASE for constants).
- Do **not** commit build output (`Debug/`, `Release/`, `x64/`, `*.obj`, `*.pdb` — these are already covered by `.gitignore`).
- If you add new audio assets, keep them small and in WAV format.

---

## License

This project was created for educational purposes as part of a university COAL course (Fall 2025). No explicit open-source license has been applied. If you wish to reuse or extend this code, please contact the repository owner.

---

*A product of Rayyan's Emporium — 24I-0767*
