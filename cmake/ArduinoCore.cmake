# cmake/ArduinoCore.cmake
# Macroscopic module: Compilation of the Arduino Core static library



# ----------------------------------------------------------------------------
# PRIVATE API / INTERNAL HELPER FUNCTIONS
# ----------------------------------------------------------------------------

# This function handles the special case of main.cpp between core / app
# Behavior: Filters out any main.cpp from the core sources to keep it as a pure library
function(_arduino_adjust_core_sources IN_OUT_SOURCES)
    set(TEMP_SOURCES ${${IN_OUT_SOURCES}})
    
    list(FILTER TEMP_SOURCES EXCLUDE REGEX "main\\.cpp$")
    
    set(${IN_OUT_SOURCES} ${TEMP_SOURCES} PARENT_SCOPE)
endfunction()



# ----------------------------------------------------------------------------
# PROTECTED API
# ----------------------------------------------------------------------------

# Signature simplified: only exact paths are needed now!
function(_arduino_prepare_core CORE_DIR VARIANT_DIR)
    # 1. Gather raw sources
    list(APPEND CORE_DIRS "${CORE_DIR}" "${VARIANT_DIR}")
    _arduino_gather_sources(CORE_SOURCES "${CORE_DIRS}")
    
    # 2. Adjust (Handle main.cpp case)
    _arduino_adjust_core_sources(CORE_SOURCES)
    
    # 3. Build target using our universal constructor
    _arduino_build_target("ArduinoCore" "STATIC" CORE_SOURCES CORE_DIRS)
endfunction()



# ----------------------------------------------------------------------------
# PUBLIC API
# ----------------------------------------------------------------------------

# nothing to expose here, the core is built internally and linked as a dependency to the app targets.

