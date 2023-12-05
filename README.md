# KNITRO.jl

[![Build Status](https://github.com/jump-dev/KNITRO.jl/workflows/CI/badge.svg?branch=master)](https://github.com/jump-dev/KNITRO.jl/actions?query=workflow%3ACI)
[![codecov](https://codecov.io/gh/jump-dev/KNITRO.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jump-dev/KNITRO.jl)

[KNITRO.jl](https://github.com/jump-dev/KNITRO.jl) is a wrapper for the
[Artelys Knitro solver](https://www.artelys.com/knitro).

It has two components:

 - a thin wrapper around the [C API](https://www.artelys.com/tools/knitro_doc/3_referenceManual/callableLibraryAPI.html)
 - an interface to [MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl).

**KNITRO.jl v0.14.0 introduced a number of breaking changes to the low-level C
API. See the Low-level wrapper section for details.**

## Affiliation

This wrapper is maintained by the JuMP community with help from Artelys.

Contact [Artelys support](mailto:support-knitro@artelys.com) if you encounter
any problem with this interface or the solver.

## License

`KNITRO.jl` is licensed under the [MIT License](https://github.com/jump-dev/KNITRO.jl/blob/master/LICENSE.md).

The underlying solver is a closed-source commercial product for which you must
[purchase a license](https://www.artelys.com/knitro).

## Installation

First, obtain a license and install a copy of KNITRO from
[Artelys](https://www.artelys.com/knitro).

Then, install `KNITRO.jl` using the Julia package manager:
```julia
import Pkg
Pkg.add("KNITRO")
```

If you are having trouble installing KNITRO.jl, here are several things to try:

- Make sure that you have defined your global variables correctly, for example
  with `export KNITRODIR="/path/to/knitro-vXXX-$OS-64"` and `export
  LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$KNITRODIR/lib"`. You can check that
  `KNITRO.jl` sees your library with `using KNITRO; KNITRO.has_knitro()`.
- If `KNITRO.has_knitro()` returns `false` but you are confident that your paths
  are correct, try running `Pkg.build("KNITRO")` and restarting Julia. In at
  least one user's experience, installing and using KNITRO in a temporary Julia
  environment (activated with `] activate --temp`) does not work and the need to
  manually build is likely the reason why.

## Use with JuMP

To use KNITRO with JuMP, use `KNITRO.Optimizer`:

```julia
using JuMP, KNITRO
model = Model(KNITRO.Optimizer)
set_attribute(model, "outlev", 1)
set_attribute(model, "algorithm", 4)
```

## Use with AMPL

To use KNITRO with [AmplNLWriter.jl](https://github.com/jump-dev/AmplNLWriter.jl),
use `KNITRO.amplexe`:

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
 * [`MOI.ObjectiveFunction{MOI.ScalarNonlinearFunction}`](@ref)
 * [`MOI.ObjectiveFunction{MOI.ScalarQuadraticFunction{Float64}}`](@ref)
 * [`MOI.ObjectiveFunction{MOI.VariableIndex}`](@ref)

List of supported variable types:

 * [`MOI.Reals`](@ref)

List of supported constraint types:

 * [`MOI.ScalarAffineFunction{Float64}`](@ref) in [`MOI.EqualTo{Float64}`](@ref)
 * [`MOI.ScalarAffineFunction{Float64}`](@ref) in [`MOI.GreaterThan{Float64}`](@ref)
 * [`MOI.ScalarAffineFunction{Float64}`](@ref) in [`MOI.Interval{Float64}`](@ref)
 * [`MOI.ScalarAffineFunction{Float64}`](@ref) in [`MOI.LessThan{Float64}`](@ref)
 * [`MOI.ScalarNonlinearFunction`](@ref) in [`MOI.EqualTo{Float64}`](@ref)
 * [`MOI.ScalarNonlinearFunction`](@ref) in [`MOI.GreaterThan{Float64}`](@ref)
 * [`MOI.ScalarNonlinearFunction`](@ref) in [`MOI.Interval{Float64}`](@ref)
 * [`MOI.ScalarNonlinearFunction`](@ref) in [`MOI.LessThan{Float64}`](@ref)
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

## Options

A list of available options is provided in the
[KNITRO reference manual](https://www.artelys.com/docs/knitro/3_referenceManual/userOptions.html).

## Low-level wrapper

The complete C API can be accessed via `KNITRO.KN_xx` functions, where the names
and arguments are identical to the C API.

See the [KNITRO documentation](https://www.artelys.com/app/docs/knitro/)
for details.

As general rules when converting from Julia to C:

 * When KNITRO requires a `Ptr{T}` that holds one element, like `double *`,
   use a `Ref{T}()`.
 * When KNITRO requires a `Ptr{T}` that holds multiple elements, use
   a `Vector{T}`.
 * When KNITRO requires a `double`, use `Cdouble`
 * When KNITRO requires an `int`, use `Cint`
 * When KNITRO requires a `NULL`, use `C_NULL`

Extensive examples using the C wrapper can be found in `examples/`.

### Breaking changes

KNITRO.jl v0.14.0 introduced a number of breaking changes to the low-level C
API. The main changes were:

1) removing Julia-specific functions like `KN_set_param`. Use the C API functions
   like `KN_set_int_param` and `KN_set_double_param_by_name`.
2) removing intermediate methods that tried to make the C API more Julia-like.
   For example, we have removed the `KN_add_var` method that returned the index of
   the variable. There is now only the method from the C API.

If you have trouble updating, please open a GitHub issue.

## Multi-threading

Due to limitations in the interaction between Julia and C, KNITRO.jl disables
multi-threading if the problem is nonlinear. This will override any options such
as `par_numthreads` that you may have set.

If you are using the low-level API, opt-in to enable multi-threading by calling
`KN_solve(model.env)` instead of `KN_solve(model)`, where `model` is the value
returned by `model = KN_new()`. Note that calling `KN_solve(model.env)` is an
advanced operation because it requires all callbacks you provide to be threadsafe.

Read [GitHub issue #93](https://github.com/jump-dev/KNITRO.jl/issues/93) for more details.
