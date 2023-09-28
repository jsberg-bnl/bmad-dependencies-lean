#!/bin/sh -
prefix=${prefix:-$HOME/Software/Bmad/packages}
# Need at least cmake version 3.13; build cmake if we don't have it
cv=$(cmake --version)
cv=${cv#cmake version }
cv=${cv%%
*}
cvmaj=${cv%%.*}
cv=${cv#$cvmaj.}
cvmin=${cv%%.*}
if [ -z "$cvmaj" ] || [ -n "${cvmaj#[0-9]}" ] || [ ! "$cvmaj" -ge 3 ] || [ "$cvmaj" -eq 3 ] && [ ! "$cvmin" -ge 12 ]
then
    cver=3.27.6
    tar xf cmake-$cver.tar.gz
    mkdir cmake-build
    cd cmake-build
    ../cmake-$cver/bootstrap --prefix=$prefix --parallel=4
    make -j 4
    make install
    cd ..
    rm -rf cmake-build cmake-$cver
    unset cver
    export PATH=$prefix/bin:$PATH
fi
unset cv cvmin cvmaj
if [ -z "$no_fgsl" ]
then
    unset fgsl_version
    case $(pkg-config --modversion gsl) in
	1*) fgsl_version=1.0.0 ;;
	2.5*) fgsl_version=1.4.0 ;;
	2.[67]*) fgsl_version=1.5.0 ;;
    esac
    if [ -n "$fgsl_version" ]
    then
	tar xf fgsl-$fgsl_version.tar.gz
	mkdir fgsl-build
	cd fgsl-build
	../fgsl-$fgsl_version/configure --prefix=$prefix --disable-static
	make
	make install
	cd ..
	rm -rf fgsl-$fgsl_version fgsl-build
    else
	echo "No compatible gsl version found, cannot build fgsl" 1>&2
	exit 1
    fi
fi
if [ -z "$no_lapack95" ]
then
    tar xf lapack95.tgz
    cp -p lapack95.cmake LAPACK95/CMakeLists.txt
    mkdir lapack95-build
    cd lapack95-build
    cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_VERBOSE_MAKEFILE=true ../LAPACK95
    make -j 4
    make install
    cd ..
    rm -rf LAPACK95 lapack95-build
fi
if [ -z "$no_plplot" ]
then
    tar xf plplot-5.15.0.tar.gz
    mkdir plplot-build
    cd plplot-build
    cmake -DDEFAULT_NO_DEVICES=ON -DPLD_pdfcairo=ON -DPLD_pscairo=ON -DPLD_pngcairo=ON -DPLD_svgcairo=ON -DPLD_xwin=ON -DHAVE_SHAPELIB=OFF -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_VERBOSE_MAKEFILE=true -DBUILD_SHARED_LIBS=ON -DUSE_RPATH=ON -DPLD_psc=OFF -DPL_HAVE_QHULL=OFF -DENABLE_tk=OFF -DENABLE_tcl=OFF -DENABLE_java=OFF -DENABLE_python=OFF -DENABLE_ada=OFF -DENABLE_wxwidgets=OFF -DENABLE_cxx=OFF -DENABLE_octave=OFF -DBUILD_TEST=OFF ../plplot-5.15.0
    make -j 4
    make install
    cd ..
    rm -rf plplot-5.15.0 plplot-build
fi
if [ -z "$no_xraylib" ]
then
    tar xf xraylib-4.1.3.tar.gz
    cd xraylib-xraylib-4.1.3
    autoreconf --install
    cd ..
    mkdir xraylib-build
    cd xraylib-build
    ../xraylib-xraylib-4.1.3/configure --prefix=$prefix --disable-idl --disable-java --disable-lua --disable-perl --disable-python --disable-python-numpy --disable-libtool-lock --disable-ruby --disable-php
    make -j 4
    make install
    cd ..
    rm -rf xraylib-xraylib-4.1.3 xraylib-build
fi
