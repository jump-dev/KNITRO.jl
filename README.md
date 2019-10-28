KNITRO.jl
=========
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://juliaopt.github.io/KNITRO.jl/latest)

The KNITRO.jl package provides an interface for using the [Artelys Knitro
solver](https://www.artelys.com/knitro) from
[Julia](http://julialang.org/). You cannot use KNITRO.jl without having
purchased and installed a copy of Knitro from [Artelys](https://www.artelys.com/knitro).
This package is available free of charge and in no way replaces or alters any
functionality of Artelys Knitro solver.

Documentation is available at
[https://juliaopt.github.io/KNITRO.jl/latest](https://juliaopt.github.io/KNITRO.jl/latest).

Note that the current package provides a wrapper both for the new Knitro's API
(whose functions start by `KN_`) and the deprecated Knitro's API (whose functions
start by `KTR_`). We recommend using the latest version of Knitro available and
the new API to get access to all of the new functionalities from the solver.
Using the new `KN_` API requires Knitro >= `v11.0`.
Refer to [Knitro documentation](https://www.artelys.com/tools/knitro_doc/3_referenceManual/callableLibraryAPI.html)
for a full specification of the Knitro's API.

*The Artelys Knitro wrapper for Julia is supported by the JuliaOpt
community (which originates the development of this package) and
Artelys. Feel free to contact [Artelys support](mailto:support-knitro@artelys.com) if you encounter
any problem with this interface or the solver.*


MathOptInterface Interface
==========================

KNITRO.jl now supports [MathOptInterface](https://github.com/JuliaOpt/MathOptInterface.jl)
and [JuMP 0.19](https://github.com/JuliaOpt/JuMP.jl). The `MathProgBase` interface has been deprecated. 

 
Here's an example showcasing various features. 

```julia
using JuMP, KNITRO
m = Model(with_optimizer(KNITRO.Optimizer, honorbnds = 1, outlev = 1, algorithm = 4)) # (1)
@variable(m, x, start = 1.2) # (2)
@variable(m, y)
@variable(m, z)
@variable(m, 4.0 <= u <= 4.0) # (3)

mysquare(x) = x^2 
register(m, :mysquare, 1, mysquare, autodiff = true) # (4)

@NLobjective(m, Min, mysquare(1 - x) + 100 * (y - x^2)^2 + u) 
@constraint(m, z == x + y)

optimize!(m)
(value(x), value(y), value(z), value(u), objective_value(m), termination_status(m)) # (5)
```

1. Setting `KNITRO` options. 
2. Setting initial conditions on variables. 
3. Setting box constraints on variables.
4. Registering a user-defined function for use in the problem. 
5. Querying various results from the solver. 

Low-level wrapper
=================

KNITRO.jl implements most of Knitro's functionalities.
If you aim at using part of Knitro's API that are not implemented
in the MathOptInterface/JuMP ecosystem, you can refer to the low
level API which wraps directly Knitro's C API (whose templates
are specified in the file `knitro.h`).

Extensive examples using the C wrapper can be found in `examples/`.


Ampl wrapper
============

The package [AmplNLWriter.jl](https://github.com/JuliaOpt/AmplNLWriter.jl")
allows to to call `knitroampl` through Julia to solve JuMP's optimization
models.

The usage is as follow:

```julia
using JuMP, KNITRO, AmplNLWriter

model = with_optimizer(AmplNLWriter.Optimizer, KNITRO.amplexe, ["outlev=3"])

```

Note that supports is still experimental for JuMP 0.19.
