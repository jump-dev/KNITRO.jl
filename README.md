# KNITRO.jl

[KNITRO.jl](https://github.com/jump-dev/KNITRO.jl) is a wrapper for the
[Artelys Knitro solver](https://www.artelys.com/knitro).

It has two components:
 - a thin wrapper around the [C API](https://www.artelys.com/tools/knitro_doc/3_referenceManual/callableLibraryAPI.html)
 - an interface to [MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl).

## Affiliation

This wrapper is maintained by the JuMP community with help from Artelys. Please
contact [Artelys support](mailto:support-knitro@artelys.com) if you encounter
any problem with this interface or the solver.

## License

`KNITRO.jl` is licensed under the [MIT License](https://github.com/jump-dev/KNITRO.jl/blob/master/LICENSE.md).

The underlying solver is a closed-source commercial product for which you must
[purchase a license](https://www.artelys.com/knitro).

## Installation

First, purchase and install a copy of Knitro from [Artelys](https://www.artelys.com/knitro).

Then, install `KNITRO.jl` using the Julia package manager:
```julia
import Pkg
Pkg.add("KNITRO")
```

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
using JuMP, KNITRO
model = Model(KNITRO.Optimizer)
set_attribute(model, "honorbnds", 1)
set_attribute(model, "outlev", 1)
set_attribute(model, "algorithm", 4)
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

## MathOptInterface API

The Knitro optimizer supports the following constraints and attributes.

List of supported objective functions:

 * [`MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}`](@ref)
 * [`MOI.ObjectiveFunction{MOI.ScalarQuadraticFunction{Float64}}`](@ref)
 * [`MOI.ObjectiveFunction{MOI.VariableIndex}`](@ref)

List of supported variable types:

 * [`MOI.Reals`](@ref)

List of supported constraint types:

 * [`MOI.ScalarAffineFunction{Float64}`](@ref) in [`MOI.EqualTo{Float64}`](@ref)
 * [`MOI.ScalarAffineFunction{Float64}`](@ref) in [`MOI.GreaterThan{Float64}`](@ref)
 * [`MOI.ScalarAffineFunction{Float64}`](@ref) in [`MOI.Interval{Float64}`](@ref)
 * [`MOI.ScalarAffineFunction{Float64}`](@ref) in [`MOI.LessThan{Float64}`](@ref)
 * [`MOI.ScalarQuadraticFunction{Float64}`](@ref) in [`MOI.EqualTo{Float64}`](@ref)
 * [`MOI.ScalarQuadraticFunction{Float64}`](@ref) in [`MOI.GreaterThan{Float64}`](@ref)
 * [`MOI.ScalarQuadraticFunction{Float64}`](@ref) in [`MOI.Interval{Float64}`](@ref)
 * [`MOI.ScalarQuadraticFunction{Float64}`](@ref) in [`MOI.LessThan{Float64}`](@ref)
 * [`MOI.VariableIndex`](@ref) in [`MOI.EqualTo{Float64}`](@ref)
 * [`MOI.VariableIndex`](@ref) in [`MOI.GreaterThan{Float64}`](@ref)
 * [`MOI.VariableIndex`](@ref) in [`MOI.Integer`](@ref)
 * [`MOI.VariableIndex`](@ref) in [`MOI.Interval{Float64}`](@ref)
 * [`MOI.VariableIndex`](@ref) in [`MOI.LessThan{Float64}`](@ref)
 * [`MOI.VariableIndex`](@ref) in [`MOI.ZeroOne`](@ref)
 * [`MOI.VectorAffineFunction{Float64}`](@ref) in [`MOI.SecondOrderCone`](@ref)
 * [`MOI.VectorOfVariables`](@ref) in [`MOI.Complements`](@ref)
 * [`MOI.VectorOfVariables`](@ref) in [`MOI.SecondOrderCone`](@ref)

List of supported model attributes:

 * [`MOI.NLPBlock()`](@ref)
 * [`MOI.NLPBlockDualStart()`](@ref)
 * [`MOI.ObjectiveSense()`](@ref)

## Low-level wrapper

KNITRO.jl implements most of Knitro's functionalities. If you aim at using part
of Knitro's API that are not implemented in the MathOptInterface/JuMP ecosystem,
you can refer to the low-level API, which wraps Knitro's C API (whose templates
are specified in the file `knitro.h`).

Extensive examples using the C wrapper can be found in `examples/`.

## Multithreading

Due to limitations in the interaction between Julia and C, KNITRO.jl disables
multithreading if the problem is nonlinear. This will override any options such
as `par_numthreads` that you may have set. Read [GitHub issue #93](https://github.com/jump-dev/KNITRO.jl/issues/93)
for more details.
