# cmake/ArduinoApp.cmake
# Macroscopic module: Application target creation and post-build actions



# ----------------------------------------------------------------------------
# PRIVATE API / INTERNAL HELPER FUNCTIONS
# ----------------------------------------------------------------------------

# This function handles the special case of main.cpp between core / app
# Behavior: Conditionally injects the Arduino default main.cpp if the user did not provide one
function(_arduino_adjust_app_sources IN_OUT_SOURCES DEFAULT_MAIN_PATH)
    set(TEMP_SOURCES ${${IN_OUT_SOURCES}})
    set(HAS_USER_MAIN FALSE)
    
    foreach(FILE_PATH ${TEMP_SOURCES})
        if(FILE_PATH MATCHES "main\\.cpp$")
            set(HAS_USER_MAIN TRUE)
        endif()
    endforeach()

    if(NOT HAS_USER_MAIN)
        list(APPEND TEMP_SOURCES "${DEFAULT_MAIN_PATH}")
    endif()
    
    set(${IN_OUT_SOURCES} ${TEMP_SOURCES} PARENT_SCOPE)
endfunction()



# ----------------------------------------------------------------------------
# PROTECTED API
# ----------------------------------------------------------------------------

# Generates post-build actions: hex file, size calculation, and flash target
function(_arduino_generate_hex_and_flash TARGET_NAME MCU_MODEL UPLOAD_PORT BAUD_RATE PROGRAMMER)
    # 1. Generate the .hex file
    add_custom_command(
        TARGET ${TARGET_NAME}.elf POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex -R .eeprom $<TARGET_FILE:${TARGET_NAME}.elf> ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}.hex
        COMMENT "Generating HEX file: ${TARGET_NAME}.hex"
    )

    # 2. Print memory usage
    add_custom_command(
        TARGET ${TARGET_NAME}.elf POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo "--------------------------------------------------"
        COMMAND ${CMAKE_SIZE} --mcu=${MCU_MODEL} -C $<TARGET_FILE:${TARGET_NAME}.elf>
        COMMAND ${CMAKE_COMMAND} -E echo "--------------------------------------------------"
        COMMENT "Calculating memory usage..."
    )

    # 3. Create the flash target (Upload to board)
    set(AVRDUDE_CONF_PATH "${ARDUINO_PACKAGES_ROOT}/arduino/tools/avrdude/6.3.0-arduino17/etc/avrdude.conf")
    
    add_custom_target(flash_${TARGET_NAME}
        COMMAND ${CMAKE_COMMAND} -E echo "Uploading to ${UPLOAD_PORT} at ${BAUD_RATE} baud..."
        COMMAND ${AVRDUDE_BIN} -C ${AVRDUDE_CONF_PATH} -v -p ${MCU_MODEL} -c ${PROGRAMMER} -P ${UPLOAD_PORT} -b ${BAUD_RATE} -D -U flash:w:${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}.hex:i
        DEPENDS ${TARGET_NAME}.elf
        COMMENT "Flashing ${TARGET_NAME} to Arduino..."
        USES_TERMINAL
    )
endfunction()

# Prepares and builds the application executable target
function(_arduino_prepare_app TARGET_NAME APP_DIR DEFAULT_MAIN_PATH)
    # Put the path in a list variable to match the builder reference requirement
    set(APP_DIRS "${APP_DIR}")
    
    # 1. Gather raw sources
    _arduino_gather_sources(APP_SOURCES "${APP_DIRS}")
    
    # 2. Adjust (Handle main.cpp case)
    _arduino_adjust_app_sources(APP_SOURCES "${DEFAULT_MAIN_PATH}")
    
    # 3. Build target using our universal constructor
    _arduino_build_target("${TARGET_NAME}" "EXECUTABLE" APP_SOURCES APP_DIRS)
endfunction()



# ----------------------------------------------------------------------------
# PUBLIC API
# ----------------------------------------------------------------------------

# Main function to configure an Arduino executable project
function(arduino_add_executable TARGET_NAME SOURCE_DIR)
    
    # 1. Prepare and build the application target
    _arduino_prepare_app("${TARGET_NAME}" "${SOURCE_DIR}" "${ARDUINO_DEFAULT_MAIN}")
    
    # 2. Link the application to the compiled static ArduinoCore library
    target_link_libraries(${TARGET_NAME}.elf PRIVATE ArduinoCore)
    
    # 3. Generate Hex, Size and Flash targets (Post-build actions)
    _arduino_generate_hex_and_flash("${TARGET_NAME}" "${JSON_MCU}" "${JSON_PORT}" "${JSON_BAUD}" "${JSON_PROGRAMMER}")

endfunction()

