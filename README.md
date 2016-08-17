KNITRO.jl
=========

The KNITRO.jl package provides an interface for using the [Artelys Knitro solver](http://artelys.com/en/optimization-tools/knitro) from [Julia](http://julialang.org/). You cannot use KNITRO.jl without having purchased and installed a copy of Knitro from [Artelys](http://artelys.com/). This package is available free of charge and in no way replaces or alters any functionality of Artelys Knitro solver.

Artelys Knitro functionality is extensive, so coverage is incomplete, but most functionality for solving linear, nonlinear, and mixed-integer programs is provided. Documentation is available on [ReadTheDocs](http://knitrojl.readthedocs.org/en/latest/knitro.html).

*The Artelys Knitro wrapper for Julia is community driven and not officially supported by Artelys. If you are an Artelys customer interested in official support for Julia, let them know!*

Setting up Knitro on Linux and OS X
-----------------------------------

1. First, you must obtain a copy of the Artelys Knitro solver and a license; trial versions and academic licenses are available from Artelys.

2. Once Artelys Knitro is installed on your machine, point the `LD_LIBRARY_PATH` (Linux) or `DYLD_LIBRARY_PATH` (OS X) variable to the Knitro library by adding, e.g.,

  ```bash
  export LD_LIBRARY_PATH="$HOME/knitro-10.0.0-z/lib:$LD_LIBRARY_PATH"
  ```

  ```bash
  export DYLD_LIBRARY_PATH="$HOME/knitro-10.0.0-z/lib:$DYLD_LIBRARY_PATH"
  ```
to your start-up file (e.g. ``.bash_profile``). **Not all environments load these variables.** You may need to set them explicitly from Julia using ``ENV["DYLD_LIBRARY_PATH"] = ...`` before ``using KNITRO``.

3. To activate Artelys Knitro for your computer you will need a valid license file. The simplest procedure is to copy each license into your `HOME` directory.

4. At the Julia prompt, run 
  ```julia
  julia> Pkg.add("KNITRO")
  ```

5. Test that Knitro works by runnning
  ```julia
  julia> Pkg.test("KNITRO")
  ```

Setting up Knitro on Windows
----------------------------

Note that currently *only 64-bit* Windows is supported. That is, you must use 64-bit Julia and install the Win64 version of Knitro.

1. First, you must obtain a copy of the Artelys Knitro solver and a license; trial versions and academic licenses are available.

2. Once Artelys Knitro is installed on your machine, add the directory containing ``knitro.dll`` to the `PATH` environment variable, as described in the Artelys Knitro documentation.

3. To activate Artelys Knitro for your computer you will need a valid license file. The simplest procedure is to copy each license into your `HOME` directory.

4. At the Julia prompt, run
  ```julia
  julia> Pkg.add("KNITRO")
  ```

5. Test that KNITRO.jl works by runnning
  ```julia
  julia> Pkg.test("KNITRO")
  ```

MathProgBase Interface
----------------------

KNITRO.jl implements the solver-independent [MathProgBase](https://github.com/JuliaOpt/MathProgBase.jl) interface, and so can be used within modeling software like [JuMP](https://github.com/JuliaOpt/JuMP.jl).

The solver object is called ``KnitroSolver``. All options listed in the [Artelys Knitro documentation](https://www.artelys.com/tools/knitro_doc/3_referenceManual/userOptions.html) may be passed directly. For example, you can run all algorithms by saying ``KnitroSolver(KTR_PARAM_ALG=KTR_ALG_MULTI)``.
