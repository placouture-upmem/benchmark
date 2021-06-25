cmake_minimum_required(VERSION 3.7)
project("microbe_cache")

# include(CheckIPOSupported)
# check_ipo_supported(RESULT ipo_supported OUTPUT output)

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin)
set(INTERMEDIATE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/intermediate)
file(MAKE_DIRECTORY ${INTERMEDIATE_OUTPUT_DIRECTORY})

set(sources create_sequence.c)
set(target "create_sequence")
add_executable(${target} ${sources})
if(ipo_supported)
  set_property(
    TARGET ${target}
    PROPERTY INTERPROCEDURAL_OPTIMIZATION True)
endif()
target_include_directories(${target} PUBLIC .)
target_compile_definitions(${target} PUBLIC ${compile_definitions})
target_compile_options(${target} PUBLIC ${compile_options})
target_link_libraries(${target} ${link_flags})

install(
  TARGETS ${target}
  RUNTIME DESTINATION bin)


set(nr_thread 1)
set(nr_access_req 1)

# minimal unroll_factor must be 1
# maximal depends on L1i cache size
set(unroll_factor 8)

set(optim -O3)
set(compile_options
  -std=c99 -Wall -Wextra -Wshadow -pedantic -Wno-unused-parameter ${optim}
  )

set(compile_definitions
  _POSIX_C_SOURCE=200112L

  PAGE_SIZE=4096

  )

foreach(acces_req RANGE 1 ${nr_access_req})
  add_custom_command(
    OUTPUT ${INTERMEDIATE_OUTPUT_DIRECTORY}/microbe_cache_local_iterator_${acces_req}.c
    COMMAND m4
    ARGS -DUNROLL=${unroll_factor} -DACCESS_REQ=${acces_req} ${CMAKE_CURRENT_SOURCE_DIR}/microbe_cache.c.m4 > ${INTERMEDIATE_OUTPUT_DIRECTORY}/microbe_cache_local_iterator_${acces_req}.c
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/microbe_cache.c.m4
    VERBATIM)
  set(sources ${INTERMEDIATE_OUTPUT_DIRECTORY}/microbe_cache_local_iterator_${acces_req}.c)
  set(target "microbe_cache_local_iterator_${acces_req}")
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

foreach(acces_req RANGE 1 ${nr_access_req})
  add_custom_command(
    OUTPUT ${INTERMEDIATE_OUTPUT_DIRECTORY}/microbe_cache_global_iterator_${acces_req}.c
    COMMAND m4
    ARGS -DUNROLL=${unroll_factor} -DACCESS_REQ=${acces_req} ${CMAKE_CURRENT_SOURCE_DIR}/microbe_cache.c.m4 > ${INTERMEDIATE_OUTPUT_DIRECTORY}/microbe_cache_global_iterator_${acces_req}.c
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/microbe_cache.c.m4
    VERBATIM)
  set(sources ${INTERMEDIATE_OUTPUT_DIRECTORY}/microbe_cache_global_iterator_${acces_req}.c)
  set(target "microbe_cache_global_iterator_${acces_req}")
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

foreach(thread_count RANGE 1 ${nr_thread})
  foreach(acces_req RANGE 1 ${nr_access_req})
    add_custom_command(
      OUTPUT ${INTERMEDIATE_OUTPUT_DIRECTORY}/microbe_cache_local_iterator_threaded_${thread_count}_${acces_req}.c
      COMMAND m4
      ARGS -DUNROLL=${unroll_factor} -DTHREAD_COUNT=${thread_count} -DACCESS_REQ=${acces_req} ${CMAKE_CURRENT_SOURCE_DIR}/microbe_cache_threaded.c.m4 > ${INTERMEDIATE_OUTPUT_DIRECTORY}/microbe_cache_local_iterator_threaded_${thread_count}_${acces_req}.c
      DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/microbe_cache_threaded.c.m4
      VERBATIM)
    set(sources ${INTERMEDIATE_OUTPUT_DIRECTORY}/microbe_cache_local_iterator_threaded_${thread_count}_${acces_req}.c)
    set(target "microbe_cache_local_iterator_threaded_${thread_count}_${acces_req}")
    add_executable(${target} ${sources})
    if(ipo_supported)
      set_property(
	TARGET ${target}
	PROPERTY INTERPROCEDURAL_OPTIMIZATION True)
    endif()
    target_include_directories(${target} PUBLIC .)
    target_compile_definitions(${target} PUBLIC -DLOCAL_ITERATOR ${compile_definitions})
    target_compile_options(${target} PUBLIC ${compile_options})
    target_link_libraries(${target} ${link_flags} Threads::Threads)

    install(
      TARGETS ${target}
      RUNTIME DESTINATION bin)
  endforeach()
endforeach()

foreach(thread_count RANGE 1 ${nr_thread})
  foreach(acces_req RANGE 1 ${nr_access_req})
    add_custom_command(
      OUTPUT ${INTERMEDIATE_OUTPUT_DIRECTORY}/microbe_cache_global_iterator_threaded_${thread_count}_${acces_req}.c
      COMMAND m4
      ARGS -DUNROLL=${unroll_factor} -DTHREAD_COUNT=${thread_count} -DACCESS_REQ=${acces_req} ${CMAKE_CURRENT_SOURCE_DIR}/microbe_cache_threaded.c.m4 > ${INTERMEDIATE_OUTPUT_DIRECTORY}/microbe_cache_global_iterator_threaded_${thread_count}_${acces_req}.c
      DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/microbe_cache_threaded.c.m4
      VERBATIM)
    set(sources ${INTERMEDIATE_OUTPUT_DIRECTORY}/microbe_cache_global_iterator_threaded_${thread_count}_${acces_req}.c)
    set(target "microbe_cache_global_iterator_threaded_${thread_count}_${acces_req}")
    add_executable(${target} ${sources})
    if(ipo_supported)
      set_property(
	TARGET ${target}
	PROPERTY INTERPROCEDURAL_OPTIMIZATION True)
    endif()
    target_include_directories(${target} PUBLIC .)
    target_compile_definitions(${target} PUBLIC -DGLOBAL_ITERATOR ${compile_definitions})
    target_compile_options(${target} PUBLIC ${compile_options})
    target_link_libraries(${target} ${link_flags} Threads::Threads)

    install(
      TARGETS ${target}
      RUNTIME DESTINATION bin)
  endforeach()
endforeach()

install(
  FILES script_create_configuration_generic.sh
  PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
  DESTINATION bin)

install(
  FILES script_execute_generic.sh
  PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
  DESTINATION bin)



# install(
#   FILES script_create_configuration_odroidxu3.sh
#   PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
#   DESTINATION bin)

# install(
#   FILES script_execute_odroidxu3.sh
#   PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
#   DESTINATION bin)

# install(
#   FILES script_create_configuration_hikey970.sh
#   PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
#   DESTINATION bin)

# install(
#   FILES script_execute_hikey970.sh
#   PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
#   DESTINATION bin)
