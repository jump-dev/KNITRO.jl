KNITRO.jl
=========

**KNITRO.jl underwent a major rewrite between versions 0.12.0 and 0.13.0,
with the low-level wrapper now being generated automatically with Clang.jl. Users of
JuMP should see no breaking changes, but if you used the lower-level C API
you will need to update your code accordingly.**


The KNITRO.jl package provides an interface for using the [Artelys Knitro
solver](https://www.artelys.com/knitro) from
[Julia](http://julialang.org/). You cannot use KNITRO.jl without having
purchased and installed a copy of Knitro from [Artelys](https://www.artelys.com/knitro).
This package is available free of charge and in no way replaces or alters any
functionality of Artelys Knitro solver.

Refer to [Knitro documentation](https://www.artelys.com/tools/knitro_doc/3_referenceManual/callableLibraryAPI.html)
for a full specification of the Knitro's API.

*The Artelys Knitro wrapper for Julia is supported by the JuMP
community (which originates the development of this package) and
Artelys. Feel free to contact [Artelys support](mailto:support-knitro@artelys.com) if you encounter
any problem with this interface or the solver.*


MathOptInterface (MOI)
======================

KNITRO.jl supports [MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl)
and [JuMP](https://github.com/jump-dev/JuMP.jl).


Here's an example showcasing various features.

```julia
using JuMP, KNITRO
m = Model(optimizer_with_attributes(KNITRO.Optimizer,
                                    "honorbnds" => 1, "outlev" => 1, "algorithm" => 4)) # (1)
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

The package [AmplNLWriter.jl](https://github.com/JuliaOpt/AmplNLWriter.jl)
allows to to call `knitroampl` through Julia to solve JuMP's optimization
models.

The usage is as follow:

```julia
using JuMP, KNITRO, AmplNLWriter

model = Model(() -> AmplNLWriter.Optimizer(KNITRO.amplexe, ["outlev=3"]))

```

