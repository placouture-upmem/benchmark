cmake_minimum_required(VERSION 3.13)
# enable_language(Fortran)

# include(CheckIPOSupported)
# check_ipo_supported(RESULT ipo_supported OUTPUT output)

# if(ipo_supported)
#   message("-- IPO is supported!")
# else()
#   message(WARNING "IPO is not supported! ${output}")
# endif()

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

include($ENV{ROOT_DIR}/cmake_dynamic_benchmark_list.txt)

install(
  DIRECTORY scripts
  DESTINATION ${CMAKE_INSTALL_PREFIX}
  USE_SOURCE_PERMISSIONS)
