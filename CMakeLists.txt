cmake_minimum_required(VERSION 3.15)

# System Configuration (must be defined before project)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR avr)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# ----------------------------------------------------------------------------
# Project Definition
# ----------------------------------------------------------------------------
project(AVR_Arduino_Project LANGUAGES C CXX ASM)

set(PROJECT_NAME "avr_app")

# MCU Definition (Will be used by Arduino.cmake as a fallback)
set(MCU "atmega328p")

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
#arduino_link_libraries(${PROJECT_NAME} Wire)

# 3. Enable Doxygen documentation generation!
arduino_enable_doxygen(${PROJECT_NAME} "${CMAKE_CURRENT_SOURCE_DIR}")