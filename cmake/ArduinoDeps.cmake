# cmake/ArduinoDeps.cmake
# Macroscopic module: Dependency libraries creation and linkage



# ----------------------------------------------------------------------------
# PRIVATE API / INTERNAL HELPER FUNCTIONS
# ----------------------------------------------------------------------------

# This module does not have private functions for now, but this section is reserved for any future internal functions.

# This function handles the special case of Arduino libraries
# Behavior: Filters out examples, extras, and .ino files to avoid compiling sketches
function(_arduino_adjust_library_sources IN_OUT_SOURCES)
    set(TEMP_SOURCES ${${IN_OUT_SOURCES}})
    
    # 1. Exclude standard non-source directories (examples, extras, tests)
    list(FILTER TEMP_SOURCES EXCLUDE REGEX "/examples/|/extras/|/test/")
    
    # 2. Exclude .ino and .pde files just in case they were captured
    list(FILTER TEMP_SOURCES EXCLUDE REGEX "\\.(ino|pde)$")
    
    set(${IN_OUT_SOURCES} ${TEMP_SOURCES} PARENT_SCOPE)
endfunction()

# ----------------------------------------------------------------------------
# PROTECTED API
# ----------------------------------------------------------------------------

# This function prepares an Arduino library target by gathering its sources and building it as a static library.
function(_arduino_prepare_library LIB_NAME LIB_PATH)
    # Put the path in a list variable so we can pass its name by reference
    list(APPEND LIB_DIRS "${LIB_PATH}")

    # 1. Gather raw sources
    _arduino_gather_sources(LIB_SOURCES "${LIB_DIRS}")

    # 2. Adjust (Filter out examples, extras, and sketches)
    _arduino_adjust_library_sources(LIB_SOURCES)
    
    # 3. Build target (No adjustment needed for dependencies)
    _arduino_build_target("${LIB_NAME}" "STATIC" LIB_SOURCES LIB_DIRS)
endfunction()



# ----------------------------------------------------------------------------
# PUBLIC API
# ----------------------------------------------------------------------------

# Links external Arduino libraries to the main application target
function(arduino_link_libraries TARGET_NAME)
    # Iterate over all library names provided after TARGET_NAME
    foreach(LIB_NAME ${ARGN}) 
        
        # Check if the library target already exists to avoid double creation
        if(NOT TARGET ${LIB_NAME}) 
            # Define standard paths to search for the library
            set(LIB_SEARCH_PATHS 
                "${ARDUINO_CORE_ROOT}/libraries/${LIB_NAME}"
                "${ARDUINO_PACKAGES_ROOT}/arduino/hardware/avr/libraries/${LIB_NAME}"
            )

            set(LIB_FOUND FALSE)
            set(LIB_TARGET_PATH "")

            # Search for the library path safely
            foreach(CURRENT_PATH ${LIB_SEARCH_PATHS})
                if(NOT LIB_FOUND)
                    if(EXISTS "${CURRENT_PATH}")
                        set(LIB_FOUND TRUE)
                        set(LIB_TARGET_PATH "${CURRENT_PATH}")
                    endif()
                endif()
            endforeach()

            if(LIB_FOUND)
                # Build the library target and link the dependency to the core library
                _arduino_prepare_library("${LIB_NAME}" "${LIB_TARGET_PATH}")  
                target_link_libraries(${LIB_NAME} PUBLIC ArduinoCore)        
            else()
                message(WARNING "Arduino dependency '${LIB_NAME}' was not found in standard paths.")
            endif()
        endif()

        # Link the newly created or existing library to the executable target
        if(TARGET ${TARGET_NAME}.elf) 
            target_link_libraries(${TARGET_NAME}.elf PRIVATE ${LIB_NAME})
        else()
            message(WARNING "Target ${TARGET_NAME}.elf does not exist yet. Ensure arduino_add_executable is called first.")
        endif()
        
    endforeach()
endfunction()

