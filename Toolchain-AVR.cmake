# Toolchain-AVR.cmake
# Configuration dynamique, portable et auto-adaptative aux versions

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR avr)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# ----------------------------------------------------------------------------
# 1. Récupération et Nettoyage de la Racine Arduino
# ----------------------------------------------------------------------------
if(NOT DEFINED ARDUINO_PACKAGES_ROOT)
    if(DEFINED ENV{LOCALAPPDATA})
        set(ARDUINO_PACKAGES_ROOT "$ENV{LOCALAPPDATA}/Arduino15/packages")
    else()
        message(FATAL_ERROR "Impossible de trouver ARDUINO_PACKAGES_ROOT. Vérifiez votre Preset.")
    endif()
endif()

# Conversion des backslashes Windows (\) en slashes CMake (/)
file(TO_CMAKE_PATH "${ARDUINO_PACKAGES_ROOT}" ARDUINO_PACKAGES_ROOT)

# ----------------------------------------------------------------------------
# 2. Auto-Détection des Versions (Le Cœur du Fix)
# ----------------------------------------------------------------------------

# A. Détection du Compilateur (avr-gcc)
# On cherche les dossiers dans tools/avr-gcc/ et on prend le dernier (le plus récent)
file(GLOB GCC_DIRS "${ARDUINO_PACKAGES_ROOT}/arduino/tools/avr-gcc/*")
list(SORT GCC_DIRS)
list(REVERSE GCC_DIRS)
list(GET GCC_DIRS 0 GCC_DIR_FOUND)
get_filename_component(AVR_GCC_VERSION "${GCC_DIR_FOUND}" NAME)

if(NOT AVR_GCC_VERSION)
    message(FATAL_ERROR "Compilateur avr-gcc introuvable dans ${ARDUINO_PACKAGES_ROOT}/arduino/tools/avr-gcc/")
endif()

message(STATUS "Auto-detected AVR GCC: ${AVR_GCC_VERSION}")

# B. Détection du Core (hardware/avr)
# On cherche les dossiers dans hardware/avr/ et on prend le dernier (ex: 1.8.7)
file(GLOB CORE_DIRS "${ARDUINO_PACKAGES_ROOT}/arduino/hardware/avr/*")
list(SORT CORE_DIRS)
list(REVERSE CORE_DIRS)
list(GET CORE_DIRS 0 CORE_DIR_FOUND)
get_filename_component(AVR_CORE_VERSION "${CORE_DIR_FOUND}" NAME)

if(NOT AVR_CORE_VERSION)
    message(FATAL_ERROR "Arduino AVR Core introuvable dans ${ARDUINO_PACKAGES_ROOT}/arduino/hardware/avr/")
endif()

message(STATUS "Auto-detected AVR Core: ${AVR_CORE_VERSION}")

# ----------------------------------------------------------------------------
# 3. Construction des Chemins Absolus
# ----------------------------------------------------------------------------
set(AVR_TOOLCHAIN_ROOT "${ARDUINO_PACKAGES_ROOT}/arduino/tools/avr-gcc/${AVR_GCC_VERSION}")
set(ARDUINO_CORE_ROOT  "${ARDUINO_PACKAGES_ROOT}/arduino/hardware/avr/${AVR_CORE_VERSION}")

# ----------------------------------------------------------------------------
# 4. Configuration des Outils
# ----------------------------------------------------------------------------
set(CMAKE_C_COMPILER   "${AVR_TOOLCHAIN_ROOT}/bin/avr-gcc.exe")
set(CMAKE_CXX_COMPILER "${AVR_TOOLCHAIN_ROOT}/bin/avr-g++.exe")
set(CMAKE_ASM_COMPILER "${AVR_TOOLCHAIN_ROOT}/bin/avr-gcc.exe")

set(CMAKE_OBJCOPY      "${AVR_TOOLCHAIN_ROOT}/bin/avr-objcopy.exe")
set(CMAKE_OBJDUMP      "${AVR_TOOLCHAIN_ROOT}/bin/avr-objdump.exe")
set(CMAKE_SIZE         "${AVR_TOOLCHAIN_ROOT}/bin/avr-size.exe")

# Recherche dynamique d'AVRDUDE (Même logique)
file(GLOB AVRDUDE_DIRS "${ARDUINO_PACKAGES_ROOT}/arduino/tools/avrdude/*")
list(SORT AVRDUDE_DIRS)
list(REVERSE AVRDUDE_DIRS)
list(GET AVRDUDE_DIRS 0 AVRDUDE_DIR_FOUND)

if(AVRDUDE_DIR_FOUND)
    set(AVRDUDE_EXECUTABLE "${AVRDUDE_DIR_FOUND}/bin/avrdude.exe")
    set(AVRDUDE_CONF       "${AVRDUDE_DIR_FOUND}/etc/avrdude.conf")
else()
    message(WARNING "Avrdude introuvable.")
endif()

# ----------------------------------------------------------------------------
# 5. Flags de Compilation
# ----------------------------------------------------------------------------
set(MCU "atmega328p" CACHE STRING "Microcontrôleur cible")
set(F_CPU 16000000)

set(COMMON_FLAGS "-mmcu=${MCU} -DF_CPU=${F_CPU}UL -Os -w -ffunction-sections -fdata-sections")

set(CMAKE_C_FLAGS_INIT   "${COMMON_FLAGS} -std=gnu11")
set(CMAKE_CXX_FLAGS_INIT "${COMMON_FLAGS} -std=gnu++11 -fno-threadsafe-statics -fpermissive -fno-exceptions")
set(CMAKE_ASM_FLAGS_INIT "${COMMON_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS_INIT "-mmcu=${MCU} -Wl,--gc-sections -fuse-linker-plugin")