# cmake/Arduino.cmake
# Arduino Framework for CMake - Modular Architecture

# ----------------------------------------------------------------------------
# Global Configuration & Dynamic Core Detection
# ----------------------------------------------------------------------------

# 1. Ensure the base packages directory is known
if(NOT DEFINED ARDUINO_PACKAGES_ROOT)
    message(FATAL_ERROR "ARDUINO_PACKAGES_ROOT is missing. Toolchain might not be loaded.")
endif()

# 2. Dynamically find the latest AVR core version
if(NOT DEFINED ARDUINO_CORE_ROOT)
    file(GLOB CORE_DIRS "${ARDUINO_PACKAGES_ROOT}/arduino/hardware/avr/*")
    list(SORT CORE_DIRS)
    list(REVERSE CORE_DIRS)
    list(GET CORE_DIRS 0 CORE_DIR_FOUND)

    if(NOT CORE_DIR_FOUND)
        message(FATAL_ERROR "Arduino AVR Core not found in ${ARDUINO_PACKAGES_ROOT}/arduino/hardware/avr/")
    endif()

    set(ARDUINO_CORE_ROOT "${CORE_DIR_FOUND}")
endif()

# 3. Define paths to internal core components
set(ARDUINO_CORE_PATH     "${ARDUINO_CORE_ROOT}/cores/arduino")
set(ARDUINO_VARIANT_PATH  "${ARDUINO_CORE_ROOT}/variants/standard")
set(ARDUINO_LIBRARIES_DIR "${ARDUINO_CORE_ROOT}/libraries")





# ----------------------------------------------------------------------------
# INTERNAL HELPERS
# ----------------------------------------------------------------------------


################################################################################
# Loads board configuration from a JSON file or uses default UNO values
function(_arduino_load_config JSON_FILE)
    if(EXISTS "${JSON_FILE}")
        # Read the file content into a variable
        file(READ "${JSON_FILE}" JSON_CONTENT)

        # Extract basic string variables
        string(JSON BOARD_MCU GET "${JSON_CONTENT}" "mcu")
        string(JSON BOARD_F_CPU GET "${JSON_CONTENT}" "f_cpu")
        string(JSON BOARD_UPLOAD_PORT GET "${JSON_CONTENT}" "upload_port")
        string(JSON BOARD_UPLOAD_BAUD GET "${JSON_CONTENT}" "upload_baud")
        string(JSON BOARD_PROGRAMMER GET "${JSON_CONTENT}" "programmer")

        # Extract the defines array
        set(BOARD_DEFINES "")
        string(JSON DEFINES_LEN LENGTH "${JSON_CONTENT}" "defines")
        
        # Calculate the max index (length - 1)
        math(EXPR DEFINES_MAX "${DEFINES_LEN} - 1")
        
        if(DEFINES_MAX GREATER_EQUAL 0)
            foreach(INDEX RANGE ${DEFINES_MAX})
                string(JSON DEF_VAL GET "${JSON_CONTENT}" "defines" ${INDEX})
                list(APPEND BOARD_DEFINES ${DEF_VAL})
            endforeach()
        endif()

        message(STATUS "--------------------------------------------------")
        message(STATUS "Board Config Loaded: MCU=${BOARD_MCU}, F_CPU=${BOARD_F_CPU}")
        message(STATUS "--------------------------------------------------")
    else()
        # Default fallback values (Arduino UNO)
        message(STATUS "--------------------------------------------------")
        message(STATUS "board.json not found. Using default UNO config.")
        message(STATUS "--------------------------------------------------")
        
        set(BOARD_MCU "atmega328p")
        set(BOARD_F_CPU "16000000UL")
        set(BOARD_UPLOAD_PORT "COM3")
        set(BOARD_UPLOAD_BAUD "115200")
        set(BOARD_PROGRAMMER "arduino")
        set(BOARD_DEFINES "ARDUINO=10819" "ARDUINO_AVR_UNO" "ARDUINO_ARCH_AVR")
    endif()

    # Pass the extracted variables to the parent scope (arduino_add_executable)
    set(MCU "${BOARD_MCU}" PARENT_SCOPE)
    set(F_CPU "${BOARD_F_CPU}" PARENT_SCOPE)
    set(AVR_UPLOAD_PORT "${BOARD_UPLOAD_PORT}" PARENT_SCOPE)
    set(AVR_BAUD_RATE "${BOARD_UPLOAD_BAUD}" PARENT_SCOPE)
    set(AVR_PROGRAMMER "${BOARD_PROGRAMMER}" PARENT_SCOPE)
    set(ARDUINO_DEFINES "${BOARD_DEFINES}" PARENT_SCOPE)
endfunction()


################################################################################
# Fetches all user sources and removes any artifacts from the build directory
function(_arduino_get_user_sources SOURCE_DIR OUT_SOURCES)
    file(GLOB_RECURSE TEMP_SOURCES CONFIGURE_DEPENDS
        "${SOURCE_DIR}/*.cpp" "${SOURCE_DIR}/*.cxx" "${SOURCE_DIR}/*.c"
        "${SOURCE_DIR}/*.S"   "${SOURCE_DIR}/*.ino" "${SOURCE_DIR}/*.h"
        "${SOURCE_DIR}/*.hpp" "${SOURCE_DIR}/*.tpp"
    )
    
    set(CLEANED_SOURCES "")
    foreach(FILE_PATH ${TEMP_SOURCES})
        file(TO_CMAKE_PATH "${FILE_PATH}" FILE_PATH_NORM)
        file(TO_CMAKE_PATH "${CMAKE_BINARY_DIR}" BIN_DIR_NORM)
        
        if(NOT FILE_PATH_NORM MATCHES "^${BIN_DIR_NORM}")
            list(APPEND CLEANED_SOURCES ${FILE_PATH})
        endif()
    endforeach()
    
    set(${OUT_SOURCES} ${CLEANED_SOURCES} PARENT_SCOPE)

    if(EXISTS "${SOURCE_DIR}/board.json")
        message(STATUS "------- AddFileDependencies: ${SOURCE_DIR}/board.json")
        list(APPEND PROJECT_SOURCES "${SOURCE_DIR}/board.json")
    endif()
endfunction()


################################################################################
# Analyzes sources to detect C++ strict mode vs Arduino mode
function(_arduino_analyze_mode SOURCES OUT_HAS_MAIN OUT_IS_ARDUINO OUT_INO_FILES)
    set(LOCAL_HAS_MAIN FALSE)
    set(LOCAL_IS_ARDUINO FALSE)
    set(LOCAL_INO_FILES "")

    foreach(SOURCE_FILE ${SOURCES})
        get_filename_component(SRC_NAME ${SOURCE_FILE} NAME)
        
        if(SRC_NAME MATCHES "^main\\.(c|cpp|cxx)$")
            set(LOCAL_HAS_MAIN TRUE)
        elseif(SRC_NAME MATCHES "\\.ino$")
            list(APPEND LOCAL_INO_FILES ${SOURCE_FILE})
            set(LOCAL_IS_ARDUINO TRUE)
        endif()
    endforeach()

    if(LOCAL_HAS_MAIN)
        message(STATUS "--------------------------------------------------")
        message(STATUS "User main detected. Core main.cpp will be ignored.")
        message(STATUS "--------------------------------------------------")
    endif()

    if(LOCAL_IS_ARDUINO)
        message(STATUS "--------------------------------------------------")
        message(STATUS "Arduino Mode enabled. Ino files found.")
        message(STATUS "--------------------------------------------------")
    else()
        message(STATUS "--------------------------------------------------")
        message(STATUS "Strict C/C++ Mode enabled.")
        message(STATUS "--------------------------------------------------")
    endif()

    set(${OUT_HAS_MAIN}   ${LOCAL_HAS_MAIN}   PARENT_SCOPE)
    set(${OUT_IS_ARDUINO} ${LOCAL_IS_ARDUINO} PARENT_SCOPE)
    set(${OUT_INO_FILES}  ${LOCAL_INO_FILES}  PARENT_SCOPE)
endfunction()


################################################################################
# Compiles the Arduino Core into a static library
function(_arduino_prepare_core HAS_USER_MAIN DEFINES F_CPU)
    if(NOT TARGET ArduinoCore)
        file(GLOB CORE_SOURCES 
            "${ARDUINO_CORE_PATH}/*.c" 
            "${ARDUINO_CORE_PATH}/*.cpp" 
            "${ARDUINO_CORE_PATH}/*.S"
            "${ARDUINO_VARIANT_PATH}/*.c" 
            "${ARDUINO_VARIANT_PATH}/*.cpp" 
            "${ARDUINO_VARIANT_PATH}/*.S"
        )

        if(HAS_USER_MAIN)
            list(FILTER CORE_SOURCES EXCLUDE REGEX "main\\.cpp$")
        endif()

        add_library(ArduinoCore STATIC ${CORE_SOURCES})
        
        target_include_directories(ArduinoCore PUBLIC
            "${ARDUINO_CORE_PATH}"
            "${ARDUINO_VARIANT_PATH}"
            "${ARDUINO_LIBRARIES_DIR}"
        )

        target_compile_definitions(ArduinoCore PUBLIC 
            ${DEFINES}
            F_CPU=${F_CPU}
        )

        # Applies MCU flag and optimization options for the Core
        target_compile_options(ArduinoCore PRIVATE
            -mmcu=${MCU}
            -Os
            -ffunction-sections
            -fdata-sections
        )
        
        # Sets clock frequency and Arduino ecosystem definitions
        target_compile_definitions(ArduinoCore PUBLIC 
            F_CPU=${F_CPU} 
            ${ARDUINO_DEFINES}
        )
    endif()
endfunction()


################################################################################
# Adds the post-build rules for hex generation, size calculation, and flashing
function(_arduino_add_firmware_targets TARGET_NAME MCU PORT BAUD PROGRAMMER)
    add_custom_command(
        TARGET ${TARGET_NAME}.elf POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex -R .eeprom $<TARGET_FILE:${TARGET_NAME}.elf> ${TARGET_NAME}.hex
        COMMAND ${CMAKE_SIZE} --mcu=${MCU} -C $<TARGET_FILE:${TARGET_NAME}.elf>
    )
    
    add_custom_target(flash
        COMMAND ${AVRDUDE_EXECUTABLE} -C ${AVRDUDE_CONF} -v -p ${MCU} -c ${PROGRAMMER} -P ${PORT} -b ${BAUD} -D -U flash:w:${TARGET_NAME}.hex:i
        DEPENDS ${TARGET_NAME}.elf
    )
endfunction()


################################################################################
# Sets up the executable target, configures IDE visibility, and applies .ino rules
function(_arduino_setup_target TARGET_NAME SOURCES IS_ARDUINO INO_FILES SOURCE_DIR)
    # Define the target and group files for IDE visibility
    source_group(TREE "${SOURCE_DIR}" FILES ${SOURCES})
    add_executable(${TARGET_NAME}.elf ${SOURCES})

    # Apply Arduino specific rules (auto-include) if necessary
    if(IS_ARDUINO)
        foreach(INO_FILE ${INO_FILES})
            set_source_files_properties(${INO_FILE} PROPERTIES LANGUAGE CXX)
            set_property(SOURCE ${INO_FILE} APPEND PROPERTY COMPILE_OPTIONS "-x" "c++" "-include" "Arduino.h")
        endforeach()
    endif()

    # Informs the compiler about the target architecture
    target_compile_options(${TARGET_NAME}.elf PRIVATE
        -mmcu=${MCU}
    )

    # Informs the linker about the target architecture
    target_link_options(${TARGET_NAME}.elf PRIVATE
        -mmcu=${MCU}
    )
endfunction()


################################################################################
# Extracts include directories from sources and links the core library
function(_arduino_configure_includes TARGET_NAME SOURCES)
    set(USER_INC_DIRS "")
    
    foreach(FILE_PATH ${SOURCES})
        get_filename_component(DIR_PATH ${FILE_PATH} DIRECTORY)
        list(APPEND USER_INC_DIRS ${DIR_PATH})
    endforeach()
    
    if(USER_INC_DIRS)
        list(REMOVE_DUPLICATES USER_INC_DIRS)
    endif()
    
    target_include_directories(${TARGET_NAME}.elf PRIVATE ${USER_INC_DIRS})
    target_link_libraries(${TARGET_NAME}.elf PRIVATE ArduinoCore m)
endfunction()





# ----------------------------------------------------------------------------
# PUBLIC API
# ----------------------------------------------------------------------------


################################################################################
# Configures a Doxygen target to automatically generate project documentation
function(arduino_enable_doxygen TARGET_NAME SOURCE_DIR)
    find_package(Doxygen)
    
    if(NOT DOXYGEN_FOUND)
        message(WARNING "--------------------------------------------------")
        message(WARNING "Doxygen not found. Documentation target disabled.")
        message(WARNING "Please install Doxygen and add it to your system PATH.")
        message(WARNING "--------------------------------------------------")
        return()
    endif()

    message(STATUS "Doxygen found. Configuring documentation target...")

    # Configure Doxygen behavior via CMake variables
    set(DOXYGEN_PROJECT_NAME "${TARGET_NAME}")
    set(DOXYGEN_OUTPUT_LANGUAGE "English") # Internal doc must be in English
    set(DOXYGEN_EXTRACT_ALL YES)
    set(DOXYGEN_GENERATE_HTML YES)
    set(DOXYGEN_GENERATE_LATEX NO)
    set(DOXYGEN_GENERATE_MAN NO)
    
    # Process all subdirectories recursively
    set(DOXYGEN_RECURSIVE YES)
    
    # Ignore the build directory to avoid parsing generated/CMake files
    set(DOXYGEN_EXCLUDE_PATTERNS "*/out/*" "*/build/*" "*/CMake*")

    # Create the custom target (e.g., 'doc_avr_app')
    set(DOC_TARGET "doc_${TARGET_NAME}")
    
    doxygen_add_docs(${DOC_TARGET} 
        "${SOURCE_DIR}"
        COMMENT "Generating English Doxygen API documentation for ${TARGET_NAME}"
    )

    message(STATUS "Run 'cmake --build . --target ${DOC_TARGET}' to generate docs.")
endfunction()


################################################################################
# Links Arduino libraries (Wire, SPI, etc.) to the target
function(arduino_link_libraries TARGET_NAME)
    # ARGN contains all arguments passed after TARGET_NAME
    foreach(LIB_NAME ${ARGN})
        
        # Define the path to the standard library
        set(LIB_PATH "${ARDUINO_LIBRARIES_DIR}/${LIB_NAME}")
        
        if(NOT EXISTS "${LIB_PATH}")
            message(WARNING "--------------------------------------------------")
            message(WARNING "Library ${LIB_NAME} not found in ${ARDUINO_LIBRARIES_DIR}")
            message(WARNING "--------------------------------------------------")
            continue()
        endif()

        # Create a unique target name for this library
        set(LIB_TARGET "ArduinoLib_${LIB_NAME}")

        # Build the library only once if multiple targets request it
        if(NOT TARGET ${LIB_TARGET})
            message(STATUS "Building Arduino Library: ${LIB_NAME}")
            
            # Recursively find all source files in the library folder
            file(GLOB_RECURSE LIB_SOURCES 
                "${LIB_PATH}/*.c" 
                "${LIB_PATH}/*.cpp"
            )

            # Create a static library
            add_library(${LIB_TARGET} STATIC ${LIB_SOURCES})
            
            # Expose standard include directories for Arduino libraries
            target_include_directories(${LIB_TARGET} PUBLIC 
                "${LIB_PATH}"
                "${LIB_PATH}/src"
                "${LIB_PATH}/utility"
            )
            
            # The library itself might depend on the Arduino Core
            target_link_libraries(${LIB_TARGET} PUBLIC ArduinoCore)
        endif()

        # Link the requested library to the user's target
        target_link_libraries(${TARGET_NAME}.elf PRIVATE ${LIB_TARGET})
        
    endforeach()
endfunction()


################################################################################
# Main function to configure an Arduino executable project
function(arduino_add_executable TARGET_NAME SOURCE_DIR)
    message(STATUS "Configuring Arduino Target: ${TARGET_NAME}")

    # 0. Load the board configuration from JSON
    _arduino_load_config("${SOURCE_DIR}/board.json")

    # 1. Gather all user project files
    _arduino_get_user_sources("${SOURCE_DIR}" PROJECT_SOURCES)

    # 2. Determine project configuration mode
    _arduino_analyze_mode("${PROJECT_SOURCES}" PROJECT_HAS_MAIN PROJECT_IS_ARDUINO PROJECT_INO_FILES)

    # 3. Setup the static core library
    _arduino_prepare_core("${PROJECT_HAS_MAIN}" "${ARDUINO_DEFINES}" "${F_CPU}")

    # 4. Create target and handle IDE visibility / Arduino specific rules
    _arduino_setup_target(${TARGET_NAME} "${PROJECT_SOURCES}" ${PROJECT_IS_ARDUINO} "${PROJECT_INO_FILES}" "${SOURCE_DIR}")

    # 5. Configure user include directories and link core libraries
    _arduino_configure_includes(${TARGET_NAME} "${PROJECT_SOURCES}")

    # 6. Generate Hex, Size and Flash targets
    _arduino_add_firmware_targets(${TARGET_NAME} "${MCU}" "${AVR_UPLOAD_PORT}" "${AVR_BAUD_RATE}" "${AVR_PROGRAMMER}")

endfunction()
