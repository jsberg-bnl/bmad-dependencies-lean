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
    cver=3.27.7
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
mkdir bdl-build
cd bdl-build
[ -n "$no_hdf5" ] && dhdf5=-DBUILD_HDF5=OFF
[ -n "$no_fgsl" ] && dfgsl=-DBUILD_FGSL=OFF
[ -n "$no_lapack95" ] && dlapack95=-DBUILD_LAPACK95=OFF
[ -n "$no_plplot" ] && dplplot=-DBUILD_PLPLOT=OFF
[ -n "$no_xraylib" ] && dxraylib=-DBUILD_XRAYLIB=OFF
cmake .. -DCMAKE_INSTALL_PREFIX="$prefix" $dhdf5 $dfgsl $dlapack95 $dplplot $dxraylib
[ -z "$no_hdf5" ] && make -j 4 hdf5
[ -z "$no_fgsl" ] && make gsl && make fgsl
[ -z "$no_lapack95" ] && make -j 4 lapack95
[ -z "$no_plplot" ] && make -j 4 plplot
[ -z "$no_xarylib" ] && make -j 4 xraylib
make install
cd ..
rm -rf bdl-build
