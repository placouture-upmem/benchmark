cmake_minimum_required(VERSION 3.13)
include(CheckIPOSupported)
check_ipo_supported(RESULT ipo_supported OUTPUT output)

# set(arch -marm -mcpu=cortex-a15 -mfpu=neon-vfpv4 -mfloat-abi=hard)
set(optim -O3
  # -funroll-loops
  )
set(compile_options
  -std=c99 -Wall -Wextra -Wshadow -pedantic -Wno-unused-parameter ${optim}
  )

#=> use DEBUG to check how array indexation is made
#=> for a dense (PAGE_SIZE:4096, CACHE_LINE_SIZE:64) on a 32bit CPU:
#   the LFSR polynomial is already fine
#=> fine tune the polynomial for a different configuration

set(compile_definitions
  __unroll_critical__
  UNROLL=64

  _POSIX_C_SOURCE=200112L

  PAGE_SIZE=4096 CACHE_LINE_SIZE=64

  # DEBUG
  # DEBUG_LFSR

  )

foreach(x RANGE 1 12)
  add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/microbe_cache_local_iterator.${x}.c
    COMMAND m4
    ARGS -I/usr/share/doc/m4/examples/ -D ACCESS_REQ=${x} ${CMAKE_CURRENT_SOURCE_DIR}/microbe_cache.c.m4 > ${CMAKE_CURRENT_BINARY_DIR}/microbe_cache_local_iterator.${x}.c
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/microbe_cache.c.m4
    VERBATIM)
  set(sources microbe_cache_local_iterator.${x}.c)
  set(target "microbe_cache_local_iterator_${x}")
  add_executable(${target} ${sources})
  if(ipo_supported)
    set_property(
      TARGET ${target}
      PROPERTY INTERPROCEDURAL_OPTIMIZATION True)
  endif()
  target_include_directories(${target} PUBLIC .)
  target_compile_definitions(${target} PUBLIC -DLOCAL_ITERATOR ${compile_definitions})
  target_compile_options(${target} PUBLIC ${compile_options})
  target_link_libraries(${target} ${link_flags})

  install(
    TARGETS ${target}
    RUNTIME DESTINATION bin)
endforeach()

foreach(x RANGE 1 12)
  add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/microbe_cache_global_iterator.${x}.c
    COMMAND m4
    ARGS -I/usr/share/doc/m4/examples/ -D ACCESS_REQ=${x} ${CMAKE_CURRENT_SOURCE_DIR}/microbe_cache.c.m4 > ${CMAKE_CURRENT_BINARY_DIR}/microbe_cache_global_iterator.${x}.c
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/microbe_cache.c.m4
    VERBATIM)
  set(sources microbe_cache_global_iterator.${x}.c)
  set(target "microbe_cache_global_iterator_${x}")
  add_executable(${target} ${sources})
  if(ipo_supported)
    set_property(
      TARGET ${target}
      PROPERTY INTERPROCEDURAL_OPTIMIZATION True)
  endif()
  target_include_directories(${target} PUBLIC .)
  target_compile_definitions(${target} PUBLIC -DGLOBAL_ITERATOR ${compile_definitions})
  target_compile_options(${target} PUBLIC ${compile_options})
  target_link_libraries(${target} ${link_flags})

  install(
    TARGETS ${target}
    RUNTIME DESTINATION bin)
endforeach()

install(
  FILES script_odroid_xu3.sh
  PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
  DESTINATION bin)
