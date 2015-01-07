KNITRO.jl
=========

The KNITRO.jl package provides an interface for using the [KNITRO solver](http://www.ziena.com/knitro.htm) from the [Julia language](http://julialang.org/). You cannot use KNITRO.jl without having purchased and installed a copy of KNITRO from [Ziena Optimization](http://www.ziena.com/). This package is available free of charge and in no way replaces or alters any functionality of Ziena's KNITRO solver.

KNITRO functionality is extensive, so coverage is incomplete, but the basic functionality for solving linear, nonlinear, and mixed-integer programs is provided. Documentation is available on [ReadTheDocs](http://knitrojl.readthedocs.org/en/latest/knitro.html).

Setting up KNITRO on Linux and OS X
-----------------------------------

1. First, you must obtain a copy of the KNITRO software and a license; trial versions and academic licenses are available [here](http://www.ziena.com/download.htm).

2. Once KNITRO is installed on your machine, point the `LD_LIBRARY_PATH` (Linux) or `DYLD_LIBRARY_PATH` (OS X) variable to the KNITRO library by adding, e.g.,

  ```bash
  export LD_LIBRARY_PATH="$HOME/knitro-9.0.1-z/lib:$LD_LIBRARY_PATH"
  ```

  ```bash
  export DYLD_LIBRARY_PATH="$HOME/knitro-9.0.1-z/lib:$DYLD_LIBRARY_PATH"
  ```
to your start-up file (e.g. ``.bash_profile``).

3. To activate KNITRO for your computer you will need a valid Ziena license file (which looks like `ziena_lic_*.txt`). The simplest procedure is to copy each license into your `HOME` directory.

4. At the Julia prompt, run 
  ```julia
  julia> Pkg.add("KNITRO")
  ```

5. Test that KNITRO works by runnning
  ```julia
  julia> Pkg.test("KNITRO")
  ```

Setting up KNITRO on Windows
----------------------------

Note that currently *only 64-bit* Windows is supported. That is, you must use 64-bit Julia and install the Win64 version of KNITRO.

1. First, you must obtain a copy of the KNITRO software and a license; trial versions and academic licenses are available [here](http://www.ziena.com/download.htm).

2. Once KNITRO is installed on your machine, add the directory containing ``knitro.dll`` to the `PATH` environment variable, as described in the KNITRO documentation. 

3. To activate KNITRO for your computer you will need a valid Ziena license file (which looks like `ziena_lic_*.txt`). The simplest procedure is to copy each license into your `HOME` directory.

4. At the Julia prompt, run
  ```julia
  julia> Pkg.add("KNITRO")
  ```

5. Test that KNITRO works by runnning
  ```julia
  julia> Pkg.test("KNITRO")
  ```
