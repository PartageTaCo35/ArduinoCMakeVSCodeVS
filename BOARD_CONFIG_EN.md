# ⚙️ Board configuration (`board.json`)

The `board.json` file is the core of your project's hardware configuration. It allows you to tell the CMake framework which microcontroller you are targeting and how to send code to it, without having to modify complex scripts.

If this file is missing from your project root, the framework will automatically use the default **Arduino Uno** configuration.

## File Structure

Here is the list of parameters expected in the file:

* **`board`**: The "human" name of the board (e.g., `uno`, `nano`). Primarily used for readability.
* **`mcu`**: The exact chip reference (e.g., `atmega328p`, `atmega2560`). Used by the GCC compiler to adapt instructions.
* **`f_cpu`** : The processor clock frequency in Hertz, followed by `UL` (Unsigned Long).
* **`upload_port`** : The serial port to which your board is connected (e.g., `COM3` under Windows, `/dev/ttyUSB0` under Linux).
* **`upload_baud`**: The communication speed for uploading. Depends on the board's bootloader.
* **`programmer`** : The protocol used by AVRDUDE to communicate with the board (usually `arduino` or `wiring`).
* **`defines`**: A list (array) of preprocessor macros that will be injected into your code and the Arduino library.

---

## 📋 Ready-to-use examples

Here are standard configurations for the most common boards.
Simply copy and paste the corresponding block into your `board.json` file and adapt the `upload_port`.



### 1. Arduino Uno (Default)
```json
{
  "board": "uno",
  "mcu": "atmega328p",
  "variant": "standard",
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

### 2. Arduino Nano (Old Bootloader)
Note: Very common on Chinese clones.
```json
{
  "board": "nano",
  "mcu": "atmega328p",
  "variant": "eightanaloginputs",
  "f_cpu": "16000000UL",
  "upload_port": "COM4",
  "upload_baud": "115200",
  "programmer": "arduino",
  "defines": [
    "ARDUINO=10819",
    "ARDUINO_AVR_NANO",
    "ARDUINO_ARCH_AVR"
  ]
}
```

### 3. Arduino Mega 2560
```json
{
  "board": "mega",
  "mcu": "atmega2560",
  "variant": "mega",
  "f_cpu": "16000000UL",
  "upload_port": "COM5",
  "upload_baud": "115200",
  "programmer": "wiring",
  "defines": [
    "ARDUINO=10819",
    "ARDUINO_AVR_MEGA2560",
    "ARDUINO_ARCH_AVR"
  ]
}
```

## 🔍 How to find the settings for an exotic board?
If your board is not in the list above, here's a foolproof trick to find the correct values:
  1. Open the official **Arduino IDE**.
  2. Go to File > Preferences, and check the boxes for **"Show verbose output during: compilation and upload"**.
  3. Select your board and its port, then compile and upload a basic program (like `Blink`).
  4. In the black console at the bottom, look for the long avr-gcc command line:
     - Look for the `-mmcu= parameter` (this will give you the `mcu`).
     - Look for the `-DF_CPU= parameter` (this will give you the `f_cpu`).
     - Look for the `-DARDUINO_AVR_...` parameters (this will give you the defines).
  5. Look for the line starting with avrdude during the upload:
     - The `-c` parameter gives you the programmer.
     - The `-b` parameter gives you the upload_baud.

⚠️ Attention
**ESP32**, **RISC-V**, and **ARM**-based boards are not AVR-based boards and therefore do not use AVR-GCC.
Please adapts yourself the logic for this type of boards.

## ⚠️ Important note on configuration
Any changes made to the `board.json` file (e.g., updating port, MCU, or flags) are not automatically applied to the build system.

To ensure your changes are correctly propagated throughout the project, you must **regenerate the CMake cache** in your IDE (usually via the "Delete Cache and Reconfigure" or "Reload CMake Project" command).
This step is essential to ensure that the new hardware definitions are correctly passed to the compiler.