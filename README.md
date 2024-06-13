# A smaller set of [Bmad](https://github.com/bmad-sim/bmad-ecosystem) dependencies
This package set has a few goals
* Put together a smaller set of [Bmad dependencies](https://github.com/bmad-sim/bmad-external-deps), removing dependencies that can be readily installed on most systems
* Start from (and include) the original sources, using the most recent released versions
* Build, with supplied scripts, those dependencies outside of the Bmad tree
* Provide instructions for building Bmad with those dependencies

The primary advantages of this are
* A smaller footprint for your Bmad distribution
* Packages only need to be built once, no matter how many times you build updated releases of Bmad
* It makes it easier to work with Bmad from the Git tree, including having multiple versions in worktrees

Using these dependencies assumes you have the following packages installed on your system via your system's package manager:
* [CMake](https://cmake.org/)
* [FFTW](https://www.fftw.org/)
* [GSL](https://www.gnu.org/software/gsl/)
* [HDF5](https://www.hdfgroup.org/solutions/hdf5/)
* [LAPACK](https://www.netlib.org/lapack/)

Some older systems will have issues with some of these packages. The CMake version may be too old. Since Bmad uses the more recent API for FGSL, an installed GSL version that is too old can be a problem. Finally on systems that require a custom-installed compiler for Bmad, the Fortran module files installed with HDF5 may not be compatible with the compiler being used. For these cases, recent versions of CMake, GSL, and HDF5 are also included, and should be built if needed (note this process has only been tested on Red Hat Enterprise Linux 7).

It also assumes you are building Bmad using the [PLplot](https://plplot.sourceforge.net/) plotting library (included in these packages) rather than using [PGPLOT](https://sites.astro.caltech.edu/~tjp/pgplot/)
## Build instructions
Starting in the directory with the files, executing `./build-deps.sh` will build the dependencies and install them under `$HOME/Software/Bmad/packages`. If you wish to use a different install prefix, you can set the environment variable `prefix` to the installation prefix that you would like. This can be done in a single line with a POSIX compatible shell (such as Bash) with
```
prefix=/my/favorite/path ./build-deps.sh
```
The advantage of the single line (over `export prefix=/my/favorite/path`) is that the environment variable is set only temporarily for the execution of `build-deps.sh`. Note that the script installs the files, so it assumes that you have write access to the specified prefix. This prefix should _not_ be where your operating system normally installs packages.

If you don't wish to build one of the packages, set the environment variable(s) `no_fgsl`, `no_hdf5`, `no_lapack95`, `no_plplot`, and/or `no_xraylib` to non-empty strings for the packages you do not wish to build.
## Using the packages for building [Bmad](https://github.com/bmad-sim/bmad-ecosystem)
For this to make sense, you should have some understanding of building Bmad; see the instructions [here](https://wiki.classe.cornell.edu/ACC/ACL/OffsiteDoc). If you are building from a "distribution" the dependencies are already included. You should remove the directories corresponding to the packages included here (`fgsl`, `gsl`, `hdf5`, `lapack95`, `plplot`, and `xraylib`) or listed above as being already installed on your system (`fftw`, `lapack`), as well as the `gnu_utilities_src` directory, to make use of these packages. If you are building from a clone of the [bmad-ecosystem git tree](https://github.com/bmad-sim/bmad-ecosystem), those dependencies will be absent. To build a particular Bmad release (named `YYYYMMDD-V`, denoting the date and version on that date) when using git, you can use `git worktree add YYYYMMDD-V YYYYMMDD-V` to create a directory `YYYYMMDD-V` containing the release, and build in there.

First you need to specify environment variables to tell Bmad where to find the packages. While you could do this by editing `dist_prefs`, I recommend a different mechanism. Instead, create a file called `user_prefs`, and either place in the `util` directory of the Bmad distribution, or instead place it anywhere you like (and name it whatever you like), and set the environment variable `BMAD_USER_PREFS` to the full path (including the filename) of the file. Within that file, put the following lines:
```
export BMAD_USER_INC_DIRS="$p/include;$p/include/fgsl;$p/include/xraylib;$p/lib/fortran/modules/lapack95;$p/lib/fortran/modules/plplot"
export BMAD_USER_LIB_DIRS="$p/lib"
```
where `$p` is replaced with the prefix you used in the package installation. Any other modifications to the defaults in `dist_prefs` can be placed in this file as well, rather than modifying `dist_prefs`.

If it was necessary to build cmake, you may also need modify your path with
```
export PATH=$p/bin:$PATH
```
## Included packages
* [CMake](https://cmake.org/), version 3.27.8. This is only built if you don't have a sufficiently recent CMake version.
* [GSL](https://www.gnu.org/software/gsl/), version 2.8, only built if needed.
* [FGSL](https://doku.lrz.de/fgsl-a-fortran-interface-to-the-gnu-scientific-library-10746505.html). Versions 1.4.0, 1.5.0, and 1.6.0 and included; the correct version is built based on the installed version of GSL. While the FGSL documentation claims version 1.6.0 is compatible only with GSL 2.7, it appears to work fine with GSL 2.8.
* [HDF5](https://www.hdfgroup.org/solutions/hdf5/), version 1.14.3, only built if needed.
* [LAPACK95](https://www.netlib.org/lapack95/), version 3.0.
* [PLplot](https://plplot.sourceforge.net/), version 5.15.0.
* [xraylib](https://github.com/tschoonj/xraylib), version 4.1.3.
