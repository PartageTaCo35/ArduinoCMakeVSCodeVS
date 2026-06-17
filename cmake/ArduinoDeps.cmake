# cmake/ArduinoDeps.cmake
# Macroscopic module: Dependency libraries creation and linkage



# ----------------------------------------------------------------------------
# PRIVATE API / INTERNAL HELPER FUNCTIONS
# ----------------------------------------------------------------------------

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

#############################################
# Fontions to manage sub-dependencies BLOC

# Cleans a semantic version string (e.g., "^2.3.5" becomes "2.3.5")
function(_arduino_parse_version RAW_VERSION OUT_CLEAN_VERSION)
    string(REGEX REPLACE "[\\^\\~\\>\\=\\< ]" "" TEMP_VERSION "${RAW_VERSION}")
    set(${OUT_CLEAN_VERSION} "${TEMP_VERSION}" PARENT_SCOPE)
endfunction()

# Validates the installed library version against the required version
# using the library.json file if available
function(_arduino_check_library_version LIB_NAME JSON_FILE_PATH REQUIRED_VERSION)
    if(EXISTS "${JSON_FILE_PATH}")
        file(READ "${JSON_FILE_PATH}" JSON_CONTENT)
        string(JSON HAS_VERSION ERROR_VARIABLE JSON_ERR TYPE "${JSON_CONTENT}" "version")
        
        if(HAS_VERSION STREQUAL "STRING")
            string(JSON INSTALLED_VERSION GET "${JSON_CONTENT}" "version")
            
            # Verify version compatibility if a requirement is set
            if(NOT REQUIRED_VERSION STREQUAL "")
                if(${INSTALLED_VERSION} VERSION_LESS ${REQUIRED_VERSION})
                    message(WARNING "Version mismatch for '${LIB_NAME}'. Required: >= ${REQUIRED_VERSION}, Installed: ${INSTALLED_VERSION}")
                else()
                    message(STATUS "Resolved '${LIB_NAME}' (v${INSTALLED_VERSION})")
                endif()
            else()
                message(STATUS "Resolved '${LIB_NAME}' (v${INSTALLED_VERSION})")
            endif()
        else()
            message(STATUS "Resolved '${LIB_NAME}' (No version string found in library.json)")
        endif()
    else()
        message(STATUS "Resolved '${LIB_NAME}' (No library.json found for version check)")
    endif()
endfunction()

# Parses and resolves sub-dependencies listed in a library.json file
function(_arduino_parse_sub_dependencies LIB_NAME JSON_FILE_PATH)
    if(EXISTS "${JSON_FILE_PATH}")
        file(READ "${JSON_FILE_PATH}" JSON_CONTENT)
        string(JSON DEPS_TYPE ERROR_VARIABLE JSON_ERR TYPE "${JSON_CONTENT}" "dependencies")
        
        if(DEPS_TYPE STREQUAL "OBJECT")
            string(JSON DEPS_COUNT LENGTH "${JSON_CONTENT}" "dependencies")
            
            if(DEPS_COUNT GREATER 0)
                math(EXPR DEPS_MAX_INDEX "${DEPS_COUNT} - 1")
                
                foreach(INDEX RANGE 0 ${DEPS_MAX_INDEX})
                    # Extract author/name and raw version
                    string(JSON DEP_FULL_NAME MEMBER "${JSON_CONTENT}" "dependencies" ${INDEX})
                    string(JSON DEP_RAW_VERSION GET "${JSON_CONTENT}" "dependencies" "${DEP_FULL_NAME}")
                    
                    # Clean up strings
                    string(REGEX REPLACE "^.*/" "" DEP_CLEAN_NAME "${DEP_FULL_NAME}")
                    _arduino_parse_version("${DEP_RAW_VERSION}" DEP_REQUIRED_VERSION)
                    
                    # Recursive resolution
                    _arduino_resolve_dependency("${DEP_CLEAN_NAME}" "${DEP_REQUIRED_VERSION}")
                    
                    # Cascade linkage
                    if(TARGET ${DEP_CLEAN_NAME})
                        target_link_libraries(${LIB_NAME} PUBLIC ${DEP_CLEAN_NAME})
                    endif()
                endforeach()
            endif()
        endif()
    endif()
endfunction()

# Core recursive function to find, verify, and build a library and its dependency tree
function(_arduino_resolve_dependency LIB_NAME REQUIRED_VERSION)
    # Process only if the target has not been created yet to avoid infinite recursion
    if(NOT TARGET ${LIB_NAME})
        
        # OS specific path resolution for Sketchbook
        if(CMAKE_HOST_SYSTEM_NAME MATCHES "Windows")
            set(USER_SKETCHBOOK_LIBS "$ENV{USERPROFILE}/Documents/Arduino/libraries")
        elseif(CMAKE_HOST_SYSTEM_NAME MATCHES "Linux")
            set(USER_SKETCHBOOK_LIBS "$ENV{HOME}/Arduino/libraries")
    elseif(CMAKE_HOST_SYSTEM_NAME MATCHES "Darwin") # MacOS
            set(USER_SKETCHBOOK_LIBS "$ENV{HOME}/Documents/Arduino/libraries")
        endif()

        set(LIB_SEARCH_PATHS 
            "${ARDUINO_CORE_ROOT}/libraries/${LIB_NAME}"
            "${ARDUINO_PACKAGES_ROOT}/arduino/hardware/avr/libraries/${LIB_NAME}"
            "${USER_SKETCHBOOK_LIBS}/${LIB_NAME}"
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
            set(JSON_FILE_PATH "${LIB_TARGET_PATH}/library.json")
            
            # 1. Verify installed version
            _arduino_check_library_version("${LIB_NAME}" "${JSON_FILE_PATH}" "${REQUIRED_VERSION}")

            # 2. Build and link to Core
            _arduino_prepare_library("${LIB_NAME}" "${LIB_TARGET_PATH}")  
            target_link_libraries(${LIB_NAME} PUBLIC ArduinoCore)

            # 3. Parse sub-dependencies recursively
            _arduino_parse_sub_dependencies("${LIB_NAME}" "${JSON_FILE_PATH}")

        else()
                message(WARNING "!!!!! Arduino dependency '${LIB_NAME}' was not found in standard paths !!!!!")
        endif()
    endif()
endfunction()

# Fontions to manage sub-dependencies BLOC
#############################################


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

# Entry point to be called from CMakeLists.txt to link Arduino dependencies
function(arduino_link_libraries TARGET_NAME)
    foreach(LIB_NAME ${ARGN})
        
        # Trigger the recursive resolution with no specific initial version requirement
        _arduino_resolve_dependency("${LIB_NAME}" "")

        if(TARGET ${TARGET_NAME}.elf)
            if(TARGET ${LIB_NAME})
                target_link_libraries(${TARGET_NAME}.elf PRIVATE ${LIB_NAME})
            endif()
        else()
            message(WARNING "Target ${TARGET_NAME}.elf does not exist yet. Ensure arduino_add_executable is called first.")
        endif()
        
    endforeach()
endfunction()