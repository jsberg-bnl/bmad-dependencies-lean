#!/bin/sh -
prefix=${prefix:-$HOME/Software/Bmad/packages}
tar xf fgsl-1.5.0.tar.gz
mkdir fgsl-build
cd fgsl-build
../fgsl-1.5.0/configure --prefix=$prefix --disable-static
make
make install
cd ..
rm -rf fgsl-1.5.0 fgsl-build
tar xf lapack95.tgz
cp -p lapack95.cmake LAPACK95/CMakeLists.txt
mkdir lapack95-build
cd lapack95-build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_VERBOSE_MAKEFILE=true ../LAPACK95
make -j 4
make install
cd ..
rm -rf LAPACK95 lapack95-build
tar xf plplot-5.15.0.tar.gz
mkdir plplot-build
cd plplot-build
cmake -DDEFAULT_NO_DEVICES=ON -DPLD_pdfcairo=ON -DPLD_pscairo=ON -DPLD_pngcairo=ON -DPLD_svgcairo=ON -DPLD_xwin=ON -DHAVE_SHAPELIB=OFF -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_VERBOSE_MAKEFILE=true -DBUILD_SHARED_LIBS=ON -DUSE_RPATH=ON -DPLD_psc=OFF -DPL_HAVE_QHULL=OFF -DENABLE_tk=OFF -DENABLE_tcl=OFF -DENABLE_java=OFF -DENABLE_python=OFF -DENABLE_ada=OFF -DENABLE_wxwidgets=OFF -DENABLE_cxx=OFF -DENABLE_octave=OFF -DBUILD_TEST=OFF ../plplot-5.15.0
make -j 4
make install
cd ..
rm -rf plplot-5.15.0 plplot-build
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
