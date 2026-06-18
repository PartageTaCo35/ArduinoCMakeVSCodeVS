# Architecture & Philosophy of the CMake Framework

This project is built upon a custom, industrial-grade CMake framework designed for embedded development on AVR microcontrollers (Arduino). The goal of this architecture is to break free from the classic Arduino IDE while maintaining its compatibility, offering a modular, fast, strict, and predictable compilation process.

## 📁 Project Tree Structure

The directory structure is divided into two parts: the root (which contains the global configuration and the toolchain) and the `cmake/` folder (which contains the generation engine).

    C:.
    │   .gitignore                 # Files ignored by Git (e.g., build/, .vs/)
    │   board.json                 # Configuration file defining the hardware target (MCU, frequency, etc.)
    │   BOARD_CONFIG_EN.md         # Board configuration documentation (English)
    │   BOARD_CONFIG_FR.md         # Board configuration documentation (French)
    │   CMakeLists.txt             # Main CMake entry point. Orchestrates the project.
    │   CMakePresets.json          # CMake presets for continuous integration and IDEs (VS2022, VSCode).
    │   LICENSE                    # Project license
    │   README fr.md               # General documentation (French)
    │   README.md                  # General documentation (English)
    │   Toolchain-AVR.cmake        # Cross-toolchain file: configures CMake to use avr-gcc instead of the native PC compiler.
    │
    └───cmake/                     # Core of the compilation framework
            Arduino.cmake          # Main orchestrator for the Arduino modules.
            ArduinoApp.cmake       # User application management module.
            ArduinoCore.cmake      # Native framework (Arduino Core) management module.
            ArduinoDeps.cmake      # Third-party libraries management module.
            ArduinoHelper.cmake    # Internal toolkit (private utility functions).

## 🧠 Design Philosophy

The framework has been architected around three major software engineering principles: the **Single Responsibility Principle (SRP)**, **Architectural Symmetry**, and **Encapsulation**.

### 1. Architectural Symmetry (The Core of the Design)

The processing of source files is divided into three distinct entities, yet they are treated with absolute symmetry. Whether compiling the Arduino core, an external library, or the final application, the execution flow remains strictly identical.

This symmetry is embodied by the three sibling modules:
* **`ArduinoCore.cmake`**: Compiles the microcontroller's base sources (`wiring.c`, `HardwareSerial.cpp`, etc.) as a static library.
* **`ArduinoDeps.cmake`**: Compiles third-party libraries (e.g., Wire, SPI) as static libraries.
* **`ArduinoApp.cmake`**: Compiles the end-user's source code and performs the linking process with the Core and Dependencies to generate the executable (`.elf` / `.hex`).

**The Unified Design Pattern:**
Each of these three modules rigorously follows the same logical sequence in three steps:
1.  **Gather**: Recursive search for source files (`.c`, `.cpp`, `.S`).
2.  **Adjust**: Surgical filtering of unwanted files (excluding `examples/` and `extras/` folders, or parasitic `.ino` sketches).
3.  **Build**: Creation of the CMake target (`add_library` or `add_executable`) and application of properties.

This pattern also relies on strict visibility management (Scope). Functions are logically classified as :
1.  **Public**: API exposed to the user in `Arduino.cmake`.
2.  **Protected**: build functions shared among internal modules.
3.  **Private**: utility methods inaccessible from the outside.

### 2. Single Responsibility Principle (SRP)

Each `.cmake` file has a unique and clearly defined role, thereby preventing a monolithic and unreadable `CMakeLists.txt`:
* The root `CMakeLists.txt` only declares the project and calls the framework.
* The `Toolchain-AVR.cmake` file does *nothing but* configure the cross-compiler.
* The `Arduino.cmake` file acts as the conductor: it includes the submodules and exposes the public API.
* The `ArduinoHelper.cmake` factories common code parts and file isolates all the complex machinery (regular expressions, directory parsing), ensuring that the other modules *only* handle target declarations.

### 3. Encapsulation and Resilience (`ArduinoHelper.cmake`)

To keep the `App`, `Core`, and `Deps` modules as clean and readable as possible, all the algorithmic complexity (regular expressions, directory parsing, CMake command abstraction) is relegated to **`ArduinoHelper.cmake`**.

This file acts as a private API (functions are prefixed with `_arduino_` to indicate they should not be called directly from the user's `CMakeLists.txt`). It ensures the robustness of the framework, largely thanks to its advanced filtering which makes the compilation completely resilient against poorly structured Arduino libraries.

---
*This framework thus provides a professional "bare-metal" development base, ready to host ambitious C/C++ projects with optimized compilation times and predictable tooling.*