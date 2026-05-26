
cmake_minimum_required(VERSION 3.20)

# System Configuration (must be defined before project)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR avr)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ----------------------------------------------------------------------------
# Project Definition
# ----------------------------------------------------------------------------
project(AVR_Arduino_Project LANGUAGES C CXX ASM)

set(PROJECT_NAME "avr_app")
set(ARDUINO_BOARD_JSON_PATH "${CMAKE_CURRENT_SOURCE_DIR}/board.json")    # Path to the board configuration file (adjust as needed). If not set, it defaults to the current source directory. Must be defined before including the Arduino.cmake module.

# ----------------------------------------------------------------------------
# Arduino Framework Import
# ----------------------------------------------------------------------------
# Include our core module that handles the build process
include("cmake/Arduino.cmake")

# ----------------------------------------------------------------------------
# Application Creation
# ----------------------------------------------------------------------------
# Call our main setup function. 
# Arg 1: Executable target name
# Arg 2: Source directory (Here ".", the root)

# 1. Create the application target
arduino_add_executable(${PROJECT_NAME} "${CMAKE_CURRENT_SOURCE_DIR}")

# 2. Link external Arduino libraries (uncomment to use)
arduino_link_libraries(${PROJECT_NAME} Wire)

# 3. Enable Doxygen documentation generation!
arduino_enable_doxygen(${PROJECT_NAME} "${CMAKE_CURRENT_SOURCE_DIR}")
