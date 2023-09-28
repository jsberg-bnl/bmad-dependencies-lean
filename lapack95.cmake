cmake_minimum_required(VERSION 3.12)
project(lapack95)
# Get variables with object file lists from the makefile
execute_process(COMMAND make -n -p
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/SRC
  OUTPUT_VARIABLE lapack95_make)
# Grab routines corresponding to lapack routines
string(REGEX MATCHALL "\n.OBJS = [^\n]+\n" lapack95_src ${lapack95_make})
string(REGEX MATCHALL "la_[a-z0-9]+\\.o" lapack95_src ${lapack95_src})
# Only keep lapack95 sources that have corresponding routines in /usr/lib/liblapack.so
find_library(lapack lapack)
if(lapack MATCHES "\.so$")
  execute_process(COMMAND nm -D ${lapack} OUTPUT_VARIABLE lapack_syms)
elseif(lapack MATCHES "\.dylib$")
  execute_process(COMMAND nm -g -U ${lapack} OUTPUT_VARIABLE lapack_syms)
else()
  message(FATAL_ERROR "LAPACK library not located")
endif()
string(REGEX MATCHALL " T [a-z0-9_]+_" lapack_syms ${lapack_syms})
string(REGEX REPLACE " T ([a-z0-9_]+)_" "\\1" lapack_syms "${lapack_syms}")
set(lapack95_good "")
foreach(f ${lapack95_src})
  string(REGEX REPLACE "la_(.*)\\.o" "\\1" f "${f}")
  list (FIND lapack_syms "${f}" in_lapack)
  if (in_lapack GREATER -1)
    list(APPEND lapack95_good "${CMAKE_SOURCE_DIR}/SRC/la_${f}.f90")
  endif()
  # Some lapack95 routine names end in an extra "1" to handle different array ranks
  string(LENGTH "${f}" lf)
  math(EXPR lf "${lf}-1")
  string(SUBSTRING "${f}" ${lf} 1 fend)
  if (fend EQUAL 1)
    string(SUBSTRING "${f}" 0 ${lf} f1)
    list (FIND lapack_syms "${f1}" in_lapack)
    if (in_lapack GREATER -1)
      list(APPEND lapack95_good "${CMAKE_SOURCE_DIR}/SRC/la_${f}.f90")
    endif()
  endif()
endforeach()
# message("${lapack95_good}")
# Also include the auxiliary routines
string(REGEX MATCHALL "\nOBJAU = [^\n]+\n" lapack95_aux ${lapack95_make})
string(REGEX MATCHALL "la_[a-z0-9_]+\\.o" lapack95_aux ${lapack95_aux})
string(REGEX REPLACE "(la_[a-z0-9_]+)\\.o" "${CMAKE_SOURCE_DIR}/SRC/\\1.f90" lapack95_aux "${lapack95_aux}")
# 
enable_language(Fortran)
add_library(lapack95 SHARED
  ${CMAKE_SOURCE_DIR}/SRC/f77_lapack_single_double_complex_dcomplex.f90
  ${CMAKE_SOURCE_DIR}/SRC/f95_lapack_single_double_complex_dcomplex.f90
  ${CMAKE_SOURCE_DIR}/SRC/la_auxmod.f90
  ${lapack95_good} ${lapack95_aux})
set_target_properties(lapack95 PROPERTIES LINKER_LANGUAGE Fortran)
target_link_libraries(lapack95 lapack blas)
install(TARGETS lapack95)
install(FILES
  ${CMAKE_CURRENT_BINARY_DIR}/f77_lapack.mod
  ${CMAKE_CURRENT_BINARY_DIR}/f95_lapack.mod
  ${CMAKE_CURRENT_BINARY_DIR}/la_auxmod.mod
  ${CMAKE_CURRENT_BINARY_DIR}/la_precision.mod
  DESTINATION lib/fortran/modules/lapack95)
