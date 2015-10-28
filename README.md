KNITRO.jl
=========

[![Join the chat at https://gitter.im/JuliaOpt/KNITRO.jl](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/JuliaOpt/KNITRO.jl?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

The KNITRO.jl package provides an interface for using the [KNITRO solver](http://www.ziena.com/knitro.htm) from the [Julia language](http://julialang.org/). You cannot use KNITRO.jl without having purchased and installed a copy of KNITRO from [Ziena Optimization](http://www.ziena.com/). This package is available free of charge and in no way replaces or alters any functionality of Ziena's KNITRO solver.

KNITRO functionality is extensive, so coverage is incomplete, but the basic functionality for solving linear, nonlinear, and mixed-integer programs is provided. Documentation is available on [ReadTheDocs](http://knitrojl.readthedocs.org/en/latest/knitro.html).

*The KNITRO wrapper for Julia is community driven and not officially supported by KNITRO. If you are a KNITRO customer interested in official support for Julia, let them know!*

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

MathProgBase Interface
----------------------

KNITRO implements the solver-independent [MathProgBase](https://github.com/JuliaOpt/MathProgBase.jl) interface,
and so can be used within modeling software like [JuMP](https://github.com/JuliaOpt/JuMP.jl).
The solver object is called ``KnitroSolver``. All options listed in the [KNITRO documentation](https://www.artelys.com/tools/knitro_doc/3_referenceManual/callableLibrary/userOptions.html) may be passed directly. For example, you can run all algorithms by saying ``KnitroSolver(KTR_PARAM_ALG=KTR_ALG_MULTI)``.
