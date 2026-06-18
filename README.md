# 🚀 Modern Arduino CMake
Tired of the classic Arduino IDE? Harness the power of **Visual Studio 2026** or **VS Code** and **CMake** to develop for AVR (Uno, Nano, etc.) with a professional-grade environment that remains accessible to hobbyists, all while keeping your Arduino habits.

## 1. Quick Start
  - Clone or copy the repository. `git clone https://github.com/PartageTaCo35/ArduinoCMakeVSCodeVS.git`
  - **Add your sources** and source subdirectories to the root folder.
  - Customize the provided CMakeLists.txt at the root as needed.
  - Configure your board in the board.json file.
  - Launch your IDE (VS or VS Code) in CMake mode and select the folder containing CMakeLists.txt.
  - Your IDE will configure the CMake project (it may ask for specific details during this step).
    - If using Visual Studio, **switch** the **Solution Explorer** to **CMake view** with a simple right-click.
  - Build & Flash: Select the flash target in your IDE to upload the code to your board.

**Prerequisites:**
  - CMake (3.19+)
  - Arduino IDE (to provide the ecosystem)
  - Optionally Doxygen for documentation.

## 2. Configure your board (board.json)
No hidden menus. Everything happens in a simple JSON file at the root.
If you don't create it, the project defaults to Arduino Uno settings.

```JSON
{
  "board": "uno",
  "mcu": "atmega328p",
  "f_cpu": "16000000UL",
  "upload_port": "COM3",
  "upload_baud": "115200",
  "programmer": "arduino",
  "defines": [
    "ARDUINO=10819",
    "ARDUINO_AVR_UNO",
    "ARDUINO_ARCH_AVR"
  ]
}
```

Details about board configuration found in **BOARD_CONFIG_EN.md** .

## 3. Flexibility and Operating Modes
The framework automatically detects and adapts to your workflow through four modes:
  - **Arduino Mode**:  Use only ```.ino``` files. The framework automatically injects ```Arduino.h``` for you.
  - **Pure C++ Mode**: Develop traditionally with ```.cpp``` and ```.h``` files.
  - **Hybrid Mode**:   Mix a ```.ino``` file for the global structure with ```.cpp``` files for your classes and drivers.
  - **Expert Mode (Root)**: You can define your own ```main.cpp``` file. In this case, the framework automatically ignores the one provided by the Arduino IDE to give you total control.

**Tip:** To understand how Arduino initializes hardware, take inspiration from the original file in your installation: ```cores/arduino/main.cpp.```

### Adding libraries or boards
The framework relies on the official ecosystem. To add a new library or board:
  - Open the **Arduino IDE**.
  - Perform the standard procedure (Library or Board Manager).
  - Simply restart the CMake configuration in your professional IDE; it will automatically detect the new components.
  
### Highlights
  - **Simplified Libraries:** To add ```Wire``` or ```SPI```, just add a single line to your CMake, respectively: ```arduino_link_libraries(your_app Wire)```, ```arduino_link_libraries(your_app SPI)``` or ```arduino_link_libraries(your_app Wire SPI)``` for both.
  - **Ultra-light Code:**     The system automatically removes unused code and optimizes the final size (LTO) to ensure your programs fit into the smallest microcontrollers.
  - **Clean Organization:**   Your folders and header files (```.h```) are correctly displayed in your IDE's tree structure for easy navigation.
  - **Syntax Highlighting Tip:** Configure your IDE to apply C++ syntax highlighting to ```.ino``` files to benefit from full auto-completion 😉.


## 4. Documentation (Optional)
If Doxygen is installed on your system, you can generate comprehensive technical documentation by running the doc_your_app target.
It is the ideal tool for maintaining complex, clean projects over the long term.

## 5. License
This project is distributed under the **MIT License**. You are free to use, modify, and share it.
