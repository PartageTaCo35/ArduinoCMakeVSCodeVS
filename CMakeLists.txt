cmake_minimum_required(VERSION 3.15)

# Configuration Système (doit être avant project)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR avr)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# ----------------------------------------------------------------------------
# Project Definition
# ----------------------------------------------------------------------------
project(AVR_Arduino_Project LANGUAGES C CXX ASM)

set(PROJECT_NAME "avr_app")

# Définition du MCU (Sera utilisé par Arduino.cmake)
set(MCU "atmega328p")

# ----------------------------------------------------------------------------
# Importation du Framework Arduino
# ----------------------------------------------------------------------------
# On inclut notre module qui gère tout
include("cmake/Arduino.cmake")

# ----------------------------------------------------------------------------
# Création de l'Application
# ----------------------------------------------------------------------------
# Appel de notre super-fonction. 
# Arg 1 : Nom de l'exécutable
# Arg 2 : Dossier où chercher les sources (Ici ".", la racine)

# 1. Création de l'application
arduino_add_executable(${PROJECT_NAME}  "${CMAKE_CURRENT_SOURCE_DIR}")

# 2. Ajout des libs externes
arduino_link_libraries(${PROJECT_NAME}  Wire)

# 3. Activation de la documentation !
arduino_enable_doxygen(${PROJECT_NAME}  "${CMAKE_CURRENT_SOURCE_DIR}")