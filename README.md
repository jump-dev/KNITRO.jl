Knitro.jl
=========

The Knitro.jl package provides an interface for using the [KNITRO solver](http://www.ziena.com/knitro.htm) from the [Julia language](http://julialang.org/). You cannot use Knitro.jl without having purchased and installed a copy of KNITRO from [Ziena Optimization](http://www.ziena.com/). This package is available free of charge and in no way replaces or alters any functionality of Ziena's KNITRO solver.

KNITRO functionality is extensive, so coverage is incomplete, but the basic functionality for solving linear, nonlinear, and mixed-integer programs is provided.

Setting up Knitro on OS X
-------------------------
Knitro isn't a listed package (yet). Here's what you need to do to install it

1. First, you must obtain a copy of the KNITRO software and a license; trial versions and academic licenses are available [here](http://www-01.ibm.com/software/websphere/products/optimization/cplex-studio-preview-edition/).

2. Once KNITRO is installed on your machine (in your home directory), point the `PATH` and `DYLD_LIBRARY_PATH` variable to the KNITRO library by adding

  ```bash
  export PATH="$HOME/knitro-9.0.1-z/knitroampl:$PATH"
  export DYLD_LIBRARY_PATH="$HOME/knitro-9.0.1-z/lib:$DYLD_LIBRARY_PATH"
  ```
  to your start-up file (e.g. ``.bash_profile``).

3. At the Julia prompt, run 
  ```julia
  julia> Pkg.clone("https://github.com/yeesian/Knitro.jl.git")
  ```
(or manually clone this module to your ``.julia`` directory).

4. Copy the dynamic libraries from `$HOME/knitro-<version-number>/lib` to `$(Pkg.dir())/Knitro.jl/deps/usr/lib`.

5. Test that KNITRO works by runnning
  ```julia
  julia> Pkg.test("Knitro.jl")
  ```
