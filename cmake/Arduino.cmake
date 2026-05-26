# cmake/Arduino.cmake
# Arduino Framework for CMake - Modular Architecture (Main Entry Point)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)


# ----------------------------------------------------------------------------
# GLOBAL CONFIGURATION & INITIALIZATION
# ----------------------------------------------------------------------------
# Allow the user to specify a custom path for board.json, default to current source dir
if(NOT DEFINED ARDUINO_BOARD_JSON_PATH)
    set(ARDUINO_BOARD_JSON_PATH "${CMAKE_CURRENT_SOURCE_DIR}/board.json")
endif()

message("\r\n\r\n\r\n")
message(STATUS "----------------------------------------------------------------------------------------------------")
message(STATUS "Loading Arduino CMake Toolchain...")
message(STATUS "Base Packages Root: ${ARDUINO_PACKAGES_ROOT}")

if(NOT DEFINED ARDUINO_PACKAGES_ROOT) #Ensure the base packages directory is known
    message(FATAL_ERROR "ARDUINO_PACKAGES_ROOT is missing. Toolchain might not be loaded.")
endif()


# ----------------------------------------------------------------------------
# FRAMEWORK MODULES LODDING
# ----------------------------------------------------------------------------
include("${CMAKE_CURRENT_LIST_DIR}/ArduinoHelper.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ArduinoCore.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ArduinoDeps.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ArduinoApp.cmake")


# ----------------------------------------------------------------------------
# HARDWARE DETECTION & VARIANT CONFIGURATION
# ----------------------------------------------------------------------------
_arduino_scpecific_dispatcher()# 3. Configure IDE workspace (Virtual folders, UI tweaks)
_arduino_detect_environment("${ARDUINO_PACKAGES_ROOT}" ARDUINO_CORE_ROOT ARDUINO_CORE_PATH AVRDUDE_BIN) # Execute dynamic environment detection and load hardware configuration
_arduino_load_config("${ARDUINO_BOARD_JSON_PATH}")

set(ARDUINO_VARIANT_PATH "${ARDUINO_CORE_ROOT}/variants/${JSON_VARIANT}")
set(ARDUINO_DEFAULT_MAIN "${ARDUINO_CORE_PATH}/main.cpp") # Setup default main.cpp path
_arduino_extract_common_include_dirs("${AVR_TOOLCHAIN_ROOT}")


# ----------------------------------------------------------------------------
# DIAGNOSTIC LOGGING
# ----------------------------------------------------------------------------
message(STATUS "*** Detected Arduino Core Path: ${ARDUINO_CORE_PATH}")
message(STATUS "*** Detected Arduino Variant Path: ${ARDUINO_VARIANT_PATH}")
message(STATUS "*** Detected AVRDUDE Binary: ${AVRDUDE_BIN}")
message(STATUS "*** Detected Common Include Dirs: ${AVR_TOOLCHAIN_ROOT}")
message(STATUS "*** Detected MCU Model: ${JSON_MCU}")
message(STATUS "*** Detected F_CPU: ${JSON_F_CPU}")
message(STATUS "*** Detected Upload Port: ${JSON_PORT}")
message(STATUS "*** Detected Upload Speed: ${JSON_BAUD}")
message(STATUS "*** Detected Programmer Type: ${JSON_PROGRAMMER}")

message(STATUS "Arduino CMake Toolchain loaded successfully.")
message(STATUS "----------------------------------------------------------------------------------------------------")


# ----------------------------------------------------------------------------
# CORE INITIALIZATION
# ----------------------------------------------------------------------------
_arduino_prepare_core("${ARDUINO_CORE_PATH}" "${ARDUINO_VARIANT_PATH}")