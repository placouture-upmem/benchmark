cmake_minimum_required(VERSION 3.13)

set(sources microbe.c)

set(arch -marm -mcpu=cortex-a15 -mfpu=neon-vfpv4 -mfloat-abi=hard)
set(optim -O3 -funroll-loops)
set(compile_options
  -std=c99 -Wall -Wextra -Wshadow -pedantic -Wno-unused-parameter ${optim}
  )

#=> use DEBUG to check how array indexation is made
#=> for a dense (PAGE_SIZE:4096, CACHE_LINE_SIZE:64) on a 32bit CPU:
#   the LFSR polynomial is already fine
#=> fine tune the polynomial for a different configuration

set(compile_definitions
  __unroll_cl__ UNROLL=8
  
  _POSIX_C_SOURCE=200112L

  PAGE_SIZE=4096 CACHE_LINE_SIZE=64

  # DEBUG
  # DEBUG_LFSR
  
  VERBOSE_OUTPUT
  )

set(target "microbe_cache")
add_executable(${target} ${sources})
target_compile_definitions(${target} PUBLIC ${compile_definitions})
target_compile_options(${target} PUBLIC ${compile_options})
target_link_libraries(${target} ${link_flags})

if(ipo_supported)
  set_property(TARGET ${target} PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
endif()

install(TARGETS ${target}
  RUNTIME DESTINATION bin)
