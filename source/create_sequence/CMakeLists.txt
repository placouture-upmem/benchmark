cmake_minimum_required(VERSION 3.7.2)
project("create_sequence")

# include(CheckIPOSupported)
# check_ipo_supported(RESULT ipo_supported OUTPUT output)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin)

set(sources create_sequence.c)
set(target "create_sequence")
add_executable(${target} ${sources})
if(ipo_supported)
  set_property(
    TARGET ${target}
    PROPERTY INTERPROCEDURAL_OPTIMIZATION True)
endif()
# target_compile_definitions(${target} PUBLIC DEBUG)
target_compile_options(${target} PUBLIC
  -std=c99 -Wall -Wextra -Wshadow -pedantic
  -Ofast -march=native)

install(
  TARGETS ${target}
  RUNTIME DESTINATION bin)

install(
  FILES script_create_sequence.sh
  PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
  DESTINATION bin)
