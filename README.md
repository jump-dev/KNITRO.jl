**KNITRO.jl underwent a major rewrite between versions 0.12.0 and 0.13.0, with
the low-level wrapper now being generated automatically with Clang.jl. Users of
JuMP should see no breaking changes, but if you used the lower-level C API you
will need to update your code accordingly.**

# KNITRO.jl

**KNITRO.jl** is a [Julia](http://julialang.org/) interface to the [Artelys Knitro solver](https://www.artelys.com/knitro).

It has two components:
 - a thin wrapper around the [C API](https://www.artelys.com/tools/knitro_doc/3_referenceManual/callableLibraryAPI.html)
 - an interface to [MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl).

*Note: This wrapper is maintained by the JuMP community with help from Artelys.
Please contact [Artelys support](mailto:support-knitro@artelys.com)
if you encounter any problem with this interface or the solver.*

## Installation

First, purchase and install a copy of Knitro from [Artelys](https://www.artelys.com/knitro).

Then, install `KNITRO.jl` using the Julia package manager:
```julia
import Pkg; Pkg.add("KNITRO")
```

`KNITRO.jl` is available free of charge and in no way replaces or alters any
functionality of Artelys Knitro solver.

### Troubleshooting

If you are having issues installing, here are several things to try:

- Make sure that you have defined your global variables correctly, for example
  with `export KNITRODIR="/path/to/knitro-vXXX-$OS-64"` and `export
  LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$KNITRODIR/lib"`. You can check that
  `KNITRO.jl` sees your library with `using KNITRO; KNITRO.has_knitro()`.

- If `KNITRO.has_knitro()` returns `false` but you are confident that your
  paths are correct, try running `build KNITRO` and restarting Julia. In at
  least one user's experience, installing and using KNITRO in a temporary Julia
  environment (activated with `] activate --temp`) does not work and the need to
  manually build is likely the reason why.

## Use with JuMP

Use the `KNITRO.Optimizer` to use KNITRO with JuMP or MathOptInterface:
```julia
using JuMP
import KNITRO
model = Model(KNITRO.Optimizer)
set_optimizer_attribute(model, "honorbnds", 1)
set_optimizer_attribute(model, "outlev", 1)
set_optimizer_attribute(model, "algorithm", 4)
```

## Use with AMPL

Pass `KNITRO.amplexe` to use KNITRO with the package
[AmplNLWriter.jl](https://github.com/jump-dev/AmplNLWriter.jl) package:
```julia
using JuMP
import AmplNLWriter
import KNITRO
model = Model(() -> AmplNLWriter.Optimizer(KNITRO.amplexe, ["outlev=3"]))
```

## Use with other packages

A variety of packages extend KNITRO.jl to support other optimization modeling
systems. These include:

 * [NLPModelsKnitro](https://github.com/JuliaSmoothOptimizers/NLPModelsKnitro.jl)
 * [Optimization.jl](http://optimization.sciml.ai/stable/)

## Low-level wrapper

KNITRO.jl implements most of Knitro's functionalities. If you aim at using part
of Knitro's API that are not implemented in the MathOptInterface/JuMP ecosystem,
you can refer to the low-level API, which wraps Knitro's C API (whose templates
are specified in the file `knitro.h`).

Extensive examples using the C wrapper can be found in `examples/`.

