cmake_minimum_required(VERSION 3.12)
project(bmad-external-dependencies)
option(BUILD_FGSL "Build FGSL" ON)
option(BUILD_LAPACK95 "Build LAPACK95" ON)
option(BUILD_PLPLOT "Build PLplot" ON)
option(BUILD_XRAYLIB "Build xraylib" ON)
enable_language(Fortran)
if (BUILD_FGSL)
  find_package(GSL)
  if (NOT GSL_FOUND)
    message(FATAL_ERROR "No gsl library found")
  endif()
  string(REPLACE "." ";" gsl_ver_parts ${GSL_VERSION})
  list(GET gsl_ver_parts 0 gsl_maj)
  list(GET gsl_ver_parts 1 gsl_min)
  if (gsl_maj EQUAL 1)
    set(fgsl_version "1.0.0")
  elseif(gsl_min EQUAL 5)
    set(fgsl_version "1.4.0")
  elseif(gsl_min GREATER 5)
    set(fgsl_version "1.5.0")
  else()
    message(FATAL_ERROR "compatible gsl version not found")
  endif()
  execute_process(COMMAND "tar" "xf" "${CMAKE_CURRENT_SOURCE_DIR}/fgsl-${fgsl_version}.tar.gz")
  if (CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
    set(fgsl_fcflags "-ffree-line-length-none")
  endif()
  if ("${CMAKE_Fortran_FLAGS}" STREQUAL "" AND DEFINED fgsl_fcflags)
    set (fgsl_fcflags "FCFLAGS=${fgsl_fcflags}")
  elseif (NOT "${CMAKE_Fortran_FLAGS}" STREQUAL "" AND NOT DEFINED fgsl_fcflags)
    set (fgsl_fcflags "FCFLAGS=${CMAKE_Fortran_FLAGS}")
  elseif (NOT "${CMAKE_Fortran_FLAGS}" STREQUAL "" AND DEFINED fgsl_fcflags)
    set (fgsl_fcflags "FCFLAGS=${CMAKE_Fortran_FLAGS} ${fgsl_fcflags}")
  endif()
  include(ExternalProject)
  ExternalProject_Add(fgsl
    SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/fgsl-${fgsl_version}"
    CONFIGURE_COMMAND
    "${CMAKE_CURRENT_BINARY_DIR}/fgsl-${fgsl_version}/configure"
    "--prefix=${CMAKE_INSTALL_PREFIX}"
    "--disable-static"
    "${fgsl_fcflags}"
    BUILD_COMMAND make -j 1
    INSTALL_COMMAND make install)
endif()
if(BUILD_LAPACK95)
  find_package(LAPACK)
  if (NOT LAPACK_FOUND)
    message(FATAL_ERROR "LAPACK library not found")
  endif()
  if (NOT LAPACK95_FOUND)
    execute_process(COMMAND "tar" "xf" "${CMAKE_CURRENT_SOURCE_DIR}/lapack95.tgz")
    set(lapack95_srcdir "${CMAKE_BINARY_DIR}/LAPACK95/SRC")
    # Get the sources to be built from the LAPAC95 Makefile
    execute_process(COMMAND make -n -p
      WORKING_DIRECTORY ${lapack95_srcdir}
      OUTPUT_VARIABLE lapack95_make)
    string(REGEX MATCHALL "\n.OBJS = [^\n]+\n" lapack95_src ${lapack95_make})
    string(REGEX MATCHALL "la_[a-z0-9]+\\.o" lapack95_src ${lapack95_src})
    # Find liblapack*.{so,dylib}
    foreach(l ${LAPACK_LIBRARIES})
      string(FIND "${l}" "liblapack" lapack_lib_found)
      if(lapack_lib_found GREATER -1)
	set(lapack_lib "${l}")
      endif()
    endforeach()
    if(NOT DEFINED lapack_lib)
      message(FATAL_ERROR "LAPACK library not found in list")
    endif()
    # Extract defined symbols from liblapack
    if (lapack_lib MATCHES "\.so.*$")
      execute_process(COMMAND nm -D ${lapack_lib} OUTPUT_VARIABLE lapack_syms)
    elseif(lapack_lib MATCHES "\.dylib.*$")
      execute_process(COMMAND nm -g -U ${lapack_lib} OUTPUT_VARIABLE lapack_syms)
    else()
      message(FATAL_ERROR "LAPACK library not dynamic library?")
    endif()
    string(REGEX MATCHALL " T [a-z0-9_]+_" lapack_syms "${lapack_syms}")
    string(REGEX REPLACE " T ([a-z0-9_]+)_" "\\1" lapack_syms "${lapack_syms}")
    # Only keep lapack95 functions that have corresponding functions in liblapack
    set(lapack95_good "")
    foreach(f ${lapack95_src})
      string(REGEX REPLACE "la_(.*)\\.o" "\\1" f "${f}")
      list (FIND lapack_syms "${f}" in_lapack)
      if (in_lapack GREATER -1)
	list(APPEND lapack95_good "${lapack95_srcdir}/la_${f}.f90")
      endif()
      # Some lapack95 routine names end in an extra "1" to handle different array ranks
      string(LENGTH "${f}" lf)
      math(EXPR lf "${lf}-1")
      string(SUBSTRING "${f}" ${lf} 1 fend)
      if (fend EQUAL 1)
	string(SUBSTRING "${f}" 0 ${lf} f1)
	list (FIND lapack_syms "${f1}" in_lapack)
	if (in_lapack GREATER -1)
	  list(APPEND lapack95_good "${lapack95_srcdir}/la_${f}.f90")
	endif()
      endif()
    endforeach()
    string(REGEX MATCHALL "\nOBJAU = [^\n]+\n" lapack95_aux "${lapack95_make}")
    message("lapack95_aux=${lapack95_aux}")
    string(REGEX MATCHALL "la_[a-z0-9_]+\\.o" lapack95_aux "${lapack95_aux}")
    message("lapack95_aux=${lapack95_aux}")
    string(REGEX REPLACE "(la_[^.]*)\\.o" "${lapack95_srcdir}/\\1.f90" lapack95_aux "${lapack95_aux}")
    message("lapack95_aux=${lapack95_aux}")
    add_library(lapack95 SHARED
      ${lapack95_srcdir}/f77_lapack_single_double_complex_dcomplex.f90
      ${lapack95_srcdir}/f95_lapack_single_double_complex_dcomplex.f90
      ${lapack95_srcdir}/la_auxmod.f90
      ${lapack95_good} ${lapack95_aux})
    set_property(TARGET lapack95
      PROPERTY Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/lapack95-prefix/modules")
    set_property(TARGET lapack95
      PROPERTY LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/lapack95-prefix/lib")
    set_target_properties(lapack95 PROPERTIES LINKER_LANGUAGE Fortran)
    target_link_libraries(lapack95 ${LAPACK_LIBRARIES})
    target_link_options(lapack95 PRIVATE ${LAPACK_LINKER_FLAGS})
    install(TARGETS lapack95)
    get_property(lapack95_module_dir TARGET lapack95 PROPERTY Fortran_MODULE_DIRECTORY)
    install(FILES
      ${lapack95_module_dir}/f77_lapack.mod
      ${lapack95_module_dir}/f95_lapack.mod
      ${lapack95_module_dir}/la_auxmod.mod
      ${lapack95_module_dir}/la_precision.mod
      DESTINATION lib/fortran/modules/lapack95)
  endif()
endif()
if(BUILD_PLPLOT)
  set(plplot_version "5.15.0")
  execute_process(
    COMMAND "tar" "xf" "${CMAKE_CURRENT_SOURCE_DIR}/plplot-${plplot_version}.tar.gz")
  ExternalProject_Add(plplot
    SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/plplot-${plplot_version}"
    CMAKE_ARGS
    "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
    "-DDEFAULT_NO_DEVICES=ON"
    "-DPLD_pdfcairo=ON"
    "-DPLD_pscairo=ON"
    "-DPLD_pngcairo=ON"
    "-DPLD_svgcairo=ON"
    "-DPLD_xwin=ON"
    "-DHAVE_SHAPELIB=OFF"
    "-DCMAKE_VERBOSE_MAKEFILE=true"
    "-DBUILD_SHARED_LIBS=ON"
    "-DUSE_RPATH=ON"
    "-DPLD_psc=OFF"
    "-DPL_HAVE_QHULL=OFF"
    "-DENABLE_tk=OFF"
    "-DENABLE_tcl=OFF"
    "-DENABLE_java=OFF"
    "-DENABLE_python=OFF"
    "-DENABLE_ada=OFF"
    "-DENABLE_wxwidgets=OFF"
    "-DENABLE_cxx=OFF"
    "-DENABLE_octave=OFF"
    "-DBUILD_TEST=OFF")
endif()
if(BUILD_XRAYLIB)
  set(xraylib_version "4.1.3")
  execute_process(COMMAND "tar" "xf" "${CMAKE_CURRENT_SOURCE_DIR}/xraylib-${xraylib_version}.tar.gz")
  set(xraylib_srcdir "${CMAKE_CURRENT_BINARY_DIR}/xraylib-xraylib-${xraylib_version}")
  execute_process(
    COMMAND "autoreconf" "--install"
    WORKING_DIRECTORY "${xraylib_srcdir}")
  ExternalProject_Add(xraylib
    SOURCE_DIR "${xraylib_srcdir}"
    CONFIGURE_COMMAND
    "${xraylib_srcdir}/configure"
    "--prefix=${CMAKE_INSTALL_PREFIX}"
    "--disable-idl"
    "--disable-java"
    "--disable-lua"
    "--disable-perl"
    "--disable-python"
    "--disable-python-numpy"
    "--disable-libtool-lock"
    "--disable-ruby"
    "--disable-php"
    BUILD_COMMAND make
    INSTALL_COMMAND make install)
endif()
