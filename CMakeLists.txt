cmake_minimum_required(VERSION 3.12)
project(bmad-external-dependencies)
option(BUILD_FGSL "Build FGSL" ON)
option(BUILD_HDF5 "Build HDF5, if needed" ON)
option(BUILD_LAPACK95 "Build LAPACK95" ON)
option(BUILD_PLPLOT "Build PLplot" ON)
option(BUILD_XRAYLIB "Build xraylib" ON)
enable_language(Fortran)
include(ExternalProject)
if(BUILD_HDF5)
  find_package(HDF5 COMPONENTS Fortran)
  if(HDF5_Fortran_FOUND)
    set(test_hdf5_fn "${CMAKE_CURRENT_BINARY_DIR}/test-hdf5.f90")
    file(WRITE "${test_hdf5_fn}" "\
program hdf5_test\n\
 use hdf5\n\
 integer err\n\
 call h5open_f(err)\n\
 call h5close_f(err)\n\
end program hdf5_test\n")
    try_compile(test_hdf5
      "${CMAKE_CURRENT_BINARY_DIR}/test-hdf5"
      SOURCES "${test_hdf5_fn}"
      LINK_LIBRARIES ${HDF5_Fortran_LIBRARIES}
      CMAKE_FLAGS "-DINCLUDE_DIRECTORIES=${HDF5_Fortran_INCLUDE_DIRS}")
    file(REMOVE "${test_hdf5_fn}")
    if (NOT test_hdf5)
      set(hdf5_version "1.14.3")
      execute_process(COMMAND "tar" "xf" "${CMAKE_CURRENT_SOURCE_DIR}/hdf5-${hdf5_version}.tar.bz2")
      ExternalProject_Add(hdf5
	SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/hdf5-${hdf5_version}"
	CONFIGURE_COMMAND
	"${CMAKE_CURRENT_BINARY_DIR}/hdf5-${hdf5_version}/configure"
	"--prefix=${CMAKE_INSTALL_PREFIX}"
	"--enable-fortran"
	"--enable-cxx"
	"--without-zlib"
	"--enable-shared"
	"--disable-static"
	"--disable-tests"
	BUILD_COMMAND make
	INSTALL_COMMAND make install)
    else()
      add_custom_target(hdf5 COMMAND "true")
    endif()
  else()
    add_custom_target(hdf5 COMMAND "true")
  endif()
endif()
if (BUILD_FGSL)
  set(fgsl_version "1.6.0")
  set(BUILD_GSL OFF)
  find_package(GSL)
  if (GSL_FOUND)
    string(REPLACE "." ";" gsl_ver_parts ${GSL_VERSION})
    list(GET gsl_ver_parts 0 gsl_maj)
    list(GET gsl_ver_parts 1 gsl_min)
    if (gsl_maj EQUAL 2 AND gsl_min EQUAL 6)
      set(fgsl_version "1.5.0")
    elseif (gsl_maj EQUAL 2 AND gsl_min EQUAL 5)
      set(fgsl_version "1.4.0")
    elseif (gsl_maj LESS 2 OR gsl_min LESS 5)
      set(BUILD_GSL ON)
    endif()
  else()
    set(BUILD_GSL ON)
  endif()
  if (BUILD_GSL)
    set(gsl_version "2.8")
    execute_process(COMMAND "tar" "xf" "${CMAKE_CURRENT_SOURCE_DIR}/gsl-${gsl_version}.tar.gz")
    ExternalProject_Add(gsl
      SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/gsl-${gsl_version}"
      CONFIGURE_COMMAND
      "${CMAKE_CURRENT_BINARY_DIR}/gsl-${gsl_version}/configure"
      "--prefix=${CMAKE_INSTALL_PREFIX}"
      "--enable-shared"
      "--disable-static"
      BUILD_COMMAND make
      INSTALL_COMMAND make install)
    if(EXISTS ENV{PKG_CONFIG_PATH})
      set(fgsl_pc_flags "PKG_CONFIG_PATH=${CMAKE_INSTALL_PREFIX}/lib/pkgconfig:$ENV{PKG_CONFIG_PATH}")
    else()
      set(fgsl_pc_flags "PKG_CONFIG_PATH=${CMAKE_INSTALL_PREFIX}/lib/pkgconfig")
    endif()
  else()
    add_custom_target(gsl "true")
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
  ExternalProject_Add(fgsl
    SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/fgsl-${fgsl_version}"
    CONFIGURE_COMMAND
    "${CMAKE_CURRENT_BINARY_DIR}/fgsl-${fgsl_version}/configure"
    "--prefix=${CMAKE_INSTALL_PREFIX}"
    "--disable-static"
    ${fgsl_fcflags}
    ${fgsl_pc_flags}
    BUILD_COMMAND make -j 1
    INSTALL_COMMAND make install)
endif()
if(BUILD_LAPACK95)
  set(BLA_VENDOR "Generic")
  find_package(LAPACK)
  if (NOT LAPACK_FOUND)
    message(FATAL_ERROR "LAPACK library not found")
  endif()
  if (NOT LAPACK95_FOUND)
    execute_process(COMMAND "tar" "xf" "${CMAKE_CURRENT_SOURCE_DIR}/lapack95.tgz")
    execute_process(COMMAND "sh" "${CMAKE_CURRENT_SOURCE_DIR}/patch-lapack95.sh")
    set(lapack_deprecated "ggsvp" "tzrqf" "geqpf" "ggsvd" "gegv" "gegs" "gelsx")
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
      string(REGEX MATCHALL " T [a-z0-9_]+_" lapack_syms "${lapack_syms}")
      string(REGEX REPLACE " T ([a-z0-9_]+)_" "\\1" lapack_syms "${lapack_syms}")
    elseif(lapack_lib MATCHES "\.dylib.*$")
      execute_process(COMMAND nm -g -U ${lapack_lib} OUTPUT_VARIABLE lapack_syms)
      string(REGEX MATCHALL " T [a-z0-9_]+_" lapack_syms "${lapack_syms}")
      string(REGEX REPLACE " T ([a-z0-9_]+)_" "\\1" lapack_syms "${lapack_syms}")
    elseif(lapack_lib MATCHES "\.tbd$")
      file(READ ${lapack_lib} lapack_syms)
      string(REGEX MATCHALL "_[a-z0-9_]+_" lapack_syms "${lapack_syms}")
      string(REGEX REPLACE "_([a-z0-9_]+)_" "\\1" lapack_syms "${lapack_syms}")
    else()
      message(FATAL_ERROR "LAPACK library not dynamic library?")
    endif()
    # Only keep lapack95 functions that have corresponding functions in liblapack
    set(lapack95_good "")
    foreach(f ${lapack95_src})
      string(REGEX REPLACE "la_(.*)\\.o" "\\1" f "${f}")
      set(is_deprecated OFF)
      foreach(d ${lapack_deprecated})
	if (f MATCHES "${d}1?$")
	  set(is_deprecated ON)
	endif()
      endforeach()
      if (NOT is_deprecated)
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
      endif()
    endforeach()
    string(REGEX MATCHALL "\nOBJAU = [^\n]+\n" lapack95_aux "${lapack95_make}")
    string(REGEX MATCHALL "la_[^.]+\\.o" lapack95_aux "${lapack95_aux}")
    string(REGEX REPLACE "(la_[^.]*)\\.o" "${lapack95_srcdir}/\\1.f90" lapack95_aux "${lapack95_aux}")
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
    "-DDEFAULT_NO_BINDINGS=ON"
    "-DENABLE_fortran=ON"
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
