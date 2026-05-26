# Toolchain-AVR.cmake
# Dynamic, portable, and version-adaptive configuration

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR avr)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# ----------------------------------------------------------------------------
# 1. Arduino Packages Root Detection (Multi-OS)
# ----------------------------------------------------------------------------
# If the variable is not defined by the user, or if it is left empty
if(NOT DEFINED ARDUINO_PACKAGES_ROOT OR ARDUINO_PACKAGES_ROOT STREQUAL "")
    if(CMAKE_HOST_SYSTEM_NAME MATCHES "Windows")
        set(ARDUINO_PACKAGES_ROOT "$ENV{LOCALAPPDATA}/Arduino15/packages")
    elseif(CMAKE_HOST_SYSTEM_NAME MATCHES "Linux")
        set(ARDUINO_PACKAGES_ROOT "$ENV{HOME}/.arduino15/packages")
    elseif(CMAKE_HOST_SYSTEM_NAME MATCHES "Darwin") # MacOS
        set(ARDUINO_PACKAGES_ROOT "$ENV{HOME}/Library/Arduino15/packages")
    else()
        message(FATAL_ERROR "Unrecognized operating system. Please define ARDUINO_PACKAGES_ROOT manually.")
    endif()
endif()

# Safety check
if(NOT EXISTS "${ARDUINO_PACKAGES_ROOT}")
    message(FATAL_ERROR "Arduino folder not found at: ${ARDUINO_PACKAGES_ROOT}. Is the Arduino IDE installed?")
endif()

# Convert Windows backslashes (\) to CMake slashes (/)
file(TO_CMAKE_PATH "${ARDUINO_PACKAGES_ROOT}" ARDUINO_PACKAGES_ROOT)

# ----------------------------------------------------------------------------
# 2. Dynamic Version Detection
# ----------------------------------------------------------------------------

# A. Compiler Detection (avr-gcc)
file(GLOB GCC_DIRS "${ARDUINO_PACKAGES_ROOT}/arduino/tools/avr-gcc/*")
list(SORT GCC_DIRS)
list(REVERSE GCC_DIRS)
list(GET GCC_DIRS 0 GCC_DIR_FOUND)
if(NOT GCC_DIR_FOUND)
    message(FATAL_ERROR "avr-gcc compiler not found in ${ARDUINO_PACKAGES_ROOT}/arduino/tools/avr-gcc/")
endif()

set(AVR_TOOLCHAIN_ROOT "${GCC_DIR_FOUND}")

# ----------------------------------------------------------------------------
# 3. Toolchain Executables Definition
# ----------------------------------------------------------------------------

# Determine the native executable suffix based on the host OS
set(EXEC_EXT "")
if(CMAKE_HOST_WIN32)
    set(EXEC_EXT ".exe")
endif()

# Force visibility in the CMake Cache for Visual Studio IntelliSense
set(CMAKE_C_COMPILER   "${AVR_TOOLCHAIN_ROOT}/bin/avr-gcc${EXEC_EXT}"     CACHE FILEPATH "C Compiler"   FORCE)
set(CMAKE_CXX_COMPILER "${AVR_TOOLCHAIN_ROOT}/bin/avr-g++${EXEC_EXT}"     CACHE FILEPATH "CXX Compiler" FORCE)
set(CMAKE_ASM_COMPILER "${AVR_TOOLCHAIN_ROOT}/bin/avr-gcc${EXEC_EXT}"     CACHE FILEPATH "ASM Compiler" FORCE)

set(CMAKE_OBJCOPY      "${AVR_TOOLCHAIN_ROOT}/bin/avr-objcopy${EXEC_EXT}" CACHE FILEPATH "Objcopy" FORCE)
set(CMAKE_OBJDUMP      "${AVR_TOOLCHAIN_ROOT}/bin/avr-objdump${EXEC_EXT}" CACHE FILEPATH "Objdump" FORCE)
set(CMAKE_SIZE         "${AVR_TOOLCHAIN_ROOT}/bin/avr-size${EXEC_EXT}"    CACHE FILEPATH "Size"    FORCE)

# Dynamic AVRDUDE search
file(GLOB AVRDUDE_DIRS "${ARDUINO_PACKAGES_ROOT}/arduino/tools/avrdude/*")
list(SORT AVRDUDE_DIRS)
list(REVERSE AVRDUDE_DIRS)
list(GET AVRDUDE_DIRS 0 AVRDUDE_DIR_FOUND)

if(AVRDUDE_DIR_FOUND)
    set(AVRDUDE_EXECUTABLE "${AVRDUDE_DIR_FOUND}/bin/avrdude${EXEC_EXT}")
    set(AVRDUDE_CONF       "${AVRDUDE_DIR_FOUND}/etc/avrdude.conf")
else()
    message(WARNING "Avrdude not found. Flashing might not work.")
endif()
