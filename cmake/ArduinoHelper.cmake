# cmake/ArduinoHelper.cmake
# Shared utility and analysis functions for the Arduino CMake framework



################################################################################
################################################################################
### UTILITY FUNCTIONS FOR ENVIRONMENT, DETECTION and CONFIGURATION
################################################################################
################################################################################

# Dynamically detects the Arduino core and toolchain paths
function(_arduino_detect_environment PACKAGES_ROOT OUT_CORE_ROOT OUT_CORE_PATH OUT_AVRDUDE_BIN)
    # Find the latest AVR core version if not already defined
    if(NOT DEFINED ARDUINO_CORE_ROOT)
        file(GLOB CORE_DIRS "${PACKAGES_ROOT}/arduino/hardware/avr/*")
        
        # filter output dirs to keep only latest version (sort and reverse to get the latest first)
        list(SORT CORE_DIRS)
        list(REVERSE CORE_DIRS)
        list(GET CORE_DIRS 0 CORE_DIR_FOUND)

        if(NOT CORE_DIR_FOUND)
            message(FATAL_ERROR "Arduino AVR Core not found in ${PACKAGES_ROOT}/arduino/hardware/avr/")
        endif()

        set(LOCAL_CORE_ROOT "${CORE_DIR_FOUND}")
    else()
        set(LOCAL_CORE_ROOT "${ARDUINO_CORE_ROOT}")
    endif()

    # Define paths to internal core components
    set(LOCAL_CORE_PATH "${LOCAL_CORE_ROOT}/cores/arduino")

    # Dynamically find AVRDUDE binary for flashing if not already defined
    if(NOT DEFINED AVRDUDE_BIN)
        file(GLOB AVRDUDE_DIRS "${PACKAGES_ROOT}/arduino/tools/avrdude/*")
        
        list(SORT AVRDUDE_DIRS)
        list(REVERSE AVRDUDE_DIRS)
        list(GET AVRDUDE_DIRS 0 AVRDUDE_DIR_FOUND)

        if(NOT AVRDUDE_DIR_FOUND)
            message(FATAL_ERROR "AVRDUDE not found in ${PACKAGES_ROOT}/arduino/tools/avrdude/")
        endif()

        set(LOCAL_AVRDUDE_BIN "${AVRDUDE_DIR_FOUND}/bin/avrdude")
    else()
        set(LOCAL_AVRDUDE_BIN "${AVRDUDE_BIN}")
    endif()

    # Export paths to the parent scope
    set(${OUT_CORE_ROOT} "${LOCAL_CORE_ROOT}" PARENT_SCOPE)
    set(${OUT_CORE_PATH} "${LOCAL_CORE_PATH}" PARENT_SCOPE)
    set(${OUT_AVRDUDE_BIN} "${LOCAL_AVRDUDE_BIN}" PARENT_SCOPE)
endfunction()

# Loads hardware configuration from a JSON file
function(_arduino_load_config JSON_FILE)
    if(EXISTS "${JSON_FILE}")
        file(READ "${JSON_FILE}" BOARD_JSON)
        message(STATUS "Loading configuration from ${JSON_FILE}")
    else()
        message(WARNING "board.json not found! Using default Arduino Uno settings.")
        set(BOARD_JSON "{ \"board\": \"uno\", \"mcu\": \"atmega328p\", \"f_cpu\": \"16000000UL\", \"upload_port\": \"COM3\", \"upload_baud\": \"115200\", \"programmer\": \"arduino\", \"defines\": [ \"ARDUINO=10819\", \"ARDUINO_AVR_UNO\", \"ARDUINO_ARCH_AVR\" ]}")
    endif()

    # Extract basic values
    string(JSON JSON_BOARD       GET ${BOARD_JSON} "board")
    string(JSON JSON_MCU         GET ${BOARD_JSON} "mcu")
    string(JSON JSON_F_CPU       GET ${BOARD_JSON} "f_cpu")
    string(JSON JSON_PORT        GET ${BOARD_JSON} "upload_port")
    string(JSON JSON_BAUD        GET ${BOARD_JSON} "upload_baud")
    string(JSON JSON_PROGRAMMER  GET ${BOARD_JSON} "programmer")

    # Variant fallback
    set(JSON_VARIANT "standard")
    if(JSON_BOARD STREQUAL "mega")
        set(JSON_VARIANT "mega")
    elseif(JSON_BOARD STREQUAL "nano")
        set(JSON_VARIANT "eightanaloginputs")
    endif()

    # Extract JSON Array of defines and convert it to a CMake list
    set(CMAKE_DEFINES "")
    string(JSON DEFINE_LENGTH LENGTH ${BOARD_JSON} "defines")
    if(DEFINE_LENGTH GREATER 0)
        math(EXPR DEFINE_LAST_INDEX "${DEFINE_LENGTH} - 1")
        foreach(INDEX RANGE ${DEFINE_LAST_INDEX})
            string(JSON DEF_VAL GET ${BOARD_JSON} "defines" ${INDEX})
            list(APPEND CMAKE_DEFINES "${DEF_VAL}")
        endforeach()
    endif()

    # Export configuration variables to CMake Cache so they are globally available
    set(JSON_BOARD      ERROR_VARIABLE JSON_ERROR "${JSON_BOARD}"          CACHE STRING "Arduino Board Type" FORCE)
    set(JSON_VARIANT    ERROR_VARIABLE JSON_ERROR "${JSON_VARIANT}"        CACHE STRING "Arduino Variant"    FORCE)
    set(JSON_MCU        ERROR_VARIABLE JSON_ERROR "${JSON_MCU}"            CACHE STRING "Target MCU"         FORCE)
    set(JSON_F_CPU      ERROR_VARIABLE JSON_ERROR "${JSON_F_CPU}"          CACHE STRING "CPU Frequency"      FORCE)
    set(JSON_PORT       ERROR_VARIABLE JSON_ERROR "${JSON_PORT}"           CACHE STRING "Upload Port"        FORCE)
    set(JSON_BAUD       ERROR_VARIABLE JSON_ERROR "${JSON_BAUD}"           CACHE STRING "Upload Baud Rate"   FORCE)
    set(JSON_PROGRAMMER ERROR_VARIABLE JSON_ERROR "${JSON_PROGRAMMER}"     CACHE STRING "Upload Programmer"  FORCE)
    set(JSON_DEFINES    ERROR_VARIABLE JSON_ERROR "${CMAKE_DEFINES}"       CACHE STRING "Compile Defines"    FORCE)

    if(JSON_ERROR)
        message(FATAL_ERROR "Error parsing JSON configuration: ${JSON_ERROR}")
    endif()
endfunction()

# Extracts standard include directories for the AVR toolchain
function(_arduino_extract_common_include_dirs AVR_TOOLCHAIN_ROOT)
    set(COMMON_INCLUDES "")
    
    # Internal toolchain includes
    list(APPEND COMMON_INCLUDES "${AVR_TOOLCHAIN_ROOT}/avr/include")
    
    # GCC includes (finding the specific version folder dynamically)
    file(GLOB GCC_VERSIONS "${AVR_TOOLCHAIN_ROOT}/lib/gcc/avr/*")
    foreach(DIR ${GCC_VERSIONS})
        if(IS_DIRECTORY "${DIR}/include")
            list(APPEND COMMON_INCLUDES "${DIR}/include")
        endif()
    endforeach()

    set(AVR_LIBC_INC "${AVR_TOOLCHAIN_ROOT}/avr/include" PARENT_SCOPE)
    set(AVR_GCC_INC "${COMMON_INCLUDES}" PARENT_SCOPE)
endfunction()

# Retrieves all subdirectories containing header files
function(_arduino_get_include_dirs DIR_LIST OUT_INCLUDE_DIRS)
    set(ALL_INCLUDES "")
    foreach(DIR ${DIR_LIST})
        file(GLOB_RECURSE HEADER_FILES "${DIR}/*.h" "${DIR}/*.hpp")
        
        foreach(HEADER_FILE ${HEADER_FILES})
            get_filename_component(HEADER_DIR "${HEADER_FILE}" DIRECTORY)
            list(APPEND ALL_INCLUDES "${HEADER_DIR}")
        endforeach()
    endforeach()
    
    if(ALL_INCLUDES)
        list(REMOVE_DUPLICATES ALL_INCLUDES)
    endif()
    
    set(${OUT_INCLUDE_DIRS} ${ALL_INCLUDES} PARENT_SCOPE)
endfunction()

# Recursively fetches all source files and headers from a given directory
function(_arduino_append_sources OUT_LIST DIR)
    # Collect all C/C++ source files, headers, and assembly files recursively
    file(GLOB_RECURSE TEMP_SOURCES 
        "${DIR}/*.c" 
        "${DIR}/*.cpp"
        "${DIR}/*.cc"
        "${DIR}/*.cxx"
        "${DIR}/*.S"
        "${DIR}/*.s"
        "${DIR}/*.h"
        "${DIR}/*.hpp"
        "${DIR}/*.hh"
        "${DIR}/*.ino"
    )

    # Convert paths to CMake format (forward slashes) and filter out duplicates
    set(CLEANED_SOURCES "")
    foreach(FILE_PATH ${TEMP_SOURCES})
        file(TO_CMAKE_PATH "${FILE_PATH}" FILE_PATH_NORM)
        list(APPEND CLEANED_SOURCES "${FILE_PATH_NORM}")
    endforeach()

    # Avoid duplicate additions
    set(CURRENT_LIST ${${OUT_LIST}})
    if(CLEANED_SOURCES)
        list(APPEND CURRENT_LIST ${CLEANED_SOURCES})
        list(REMOVE_DUPLICATES CURRENT_LIST)
    endif()

    set(${OUT_LIST} ${CURRENT_LIST} PARENT_SCOPE)
endfunction()



################################################################################
################################################################################
### UNIVERSAL BUILDER FUNCTIONS
################################################################################
################################################################################

# Gathers all source files from a list of directories
function(_arduino_gather_sources OUT_SOURCES_VAR SOURCE_DIRS)
    set(GATHERED_FILES "")
    
    foreach(DIR ${SOURCE_DIRS})
        set(TEMP_SOURCES "")
        _arduino_append_sources(TEMP_SOURCES "${DIR}")
        list(APPEND GATHERED_FILES ${TEMP_SOURCES})
    endforeach()
    
    set(${OUT_SOURCES_VAR} ${GATHERED_FILES} PARENT_SCOPE)
endfunction()

# Dispatch sources into IDE-specific virtual folders if needed
function(_arduino_specific_dispatcher)
    # Force IDEs (like Visual Studio) to group external framework files into a virtual folder
    # This prevents the IDE tree from going all the way up to the user's home directory
    source_group("Arduino Framework" REGULAR_EXPRESSION ".*packages/arduino/.*")
endfunction()

# Universal target generator for Core, Libraries, and App
# Expects target name, type, and the NAMES of the variables containing sources and include directories
function(_arduino_build_target TARGET_NAME TARGET_TYPE SOURCES_VAR INCLUDE_DIRS_VAR)
    # Dereference the variable names to get the actual lists
    set(ALL_SOURCES ${${SOURCES_VAR}})
    set(ALL_INCLUDES ${${INCLUDE_DIRS_VAR}})

    message(STATUS "Building ${TARGET_TYPE}: ${TARGET_NAME}")

    # 1. Target creation based on type
    if(TARGET_TYPE STREQUAL "EXECUTABLE")
        set(ACTUAL_TARGET "${TARGET_NAME}.elf")
        add_executable(${ACTUAL_TARGET} ${ALL_SOURCES})
    elseif(TARGET_TYPE STREQUAL "STATIC")
        set(ACTUAL_TARGET "${TARGET_NAME}")
        add_library(${ACTUAL_TARGET} STATIC ${ALL_SOURCES})
    else()
        message(FATAL_ERROR "Unknown target type: ${TARGET_TYPE}")
    endif()

    # Map .ino files to C++ and forcefully inject Arduino.h to replicate IDE behavior
    foreach(SRC_FILE ${ALL_SOURCES})
        if(SRC_FILE MATCHES "\\.ino$")
            set_source_files_properties("${SRC_FILE}" PROPERTIES LANGUAGE CXX)
            set_property(SOURCE "${SRC_FILE}" APPEND_STRING PROPERTY COMPILE_FLAGS " -include Arduino.h")
        endif()
    endforeach()

    # 2. Dynamic Includes using the provided clean list
    _arduino_get_include_dirs("${ALL_INCLUDES}" TARGET_INCLUDES)
    
    # Never use SYSTEM here to avoid atexit and WString duplication issues.
    # On the avr-gcc cross-compilation chain, when a directory is included via -isystem, 
    # the compiler assumes by default that it is an old C system library.
    # To ensure compatibility, GCC takes the initiative to implicitly wrap the entire 
    # contents of the header files (including Arduino.h) in a gigantic virtual extern "C" block.
    target_include_directories(${ACTUAL_TARGET} PUBLIC 
        ${TARGET_INCLUDES}
        ${AVR_LIBC_INC}    
        ${AVR_GCC_INC} 
    )

    # 3. Standard AVR compiler flags and optimization
    target_compile_options(${ACTUAL_TARGET} PRIVATE 
        -mmcu=${JSON_MCU} 
        -Os 
        -ffunction-sections 
        -fdata-sections
        $<$<COMPILE_LANGUAGE:CXX>:-std=gnu++11>
        $<$<COMPILE_LANGUAGE:CXX>:-fpermissive>
        $<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>
        $<$<COMPILE_LANGUAGE:CXX>:-fno-threadsafe-statics>
        $<$<COMPILE_LANGUAGE:C>:-std=gnu11>
    )

    # 4. Linker options (Dead code elimination)
    if(TARGET_TYPE STREQUAL "EXECUTABLE")
        target_link_options(${ACTUAL_TARGET} PRIVATE 
            -mmcu=${JSON_MCU}
            -Wl,--gc-sections
        )
    endif()
    
    # 5. Global definitions
    target_compile_definitions(${ACTUAL_TARGET} PUBLIC 
        F_CPU=${JSON_F_CPU}
        ${JSON_DEFINES}
    )
endfunction()



################################################################################
################################################################################
### PUBLIC API
################################################################################
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

    message("\r\n")
    message(STATUS "Doxygen found. Configuring documentation target...")

    # Configure Doxygen behavior via CMake variables
    set(DOXYGEN_PROJECT_NAME    "${TARGET_NAME}")
    set(DOXYGEN_OUTPUT_LANGUAGE "English") # Internal doc must be in English
    set(DOXYGEN_EXTRACT_ALL     YES)
    set(DOXYGEN_GENERATE_HTML   YES)
    set(DOXYGEN_GENERATE_LATEX  NO)
    set(DOXYGEN_GENERATE_MAN    NO)
    
    # Process all subdirectories recursively
    set(DOXYGEN_RECURSIVE YES)
    
    # Ignore the build directory to avoid parsing generated/CMake files
    set(DOXYGEN_EXCLUDE_PATTERNS "*/out/*" "*/build/*" "*/CMake*")

    # Create the custom target (e.g., 'doc_avr_app')
    set(DOC_TARGET "doc_${TARGET_NAME}")
    
    doxygen_add_docs(${DOC_TARGET} 
        "${SOURCE_DIR}"
        ALL
        COMMENT "Generating API documentation with Doxygen"
    )

    message(STATUS "Run 'cmake --build . --target ${DOC_TARGET}' to generate docs.")
    message("\r\n")
endfunction()

