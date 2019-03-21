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

**Note: MathOptInterface works only with the new Knitro's `KN` API which requires Knitro >= `v11.0`.**

KNITRO.jl now supports [MathOptInterface](https://github.com/JuliaOpt/MathOptInterface.jl)
and [JuMP 0.19](https://github.com/JuliaOpt/JuMP.jl).

```julia
using JuMP, KNITRO

model = with_optimizer(KNITRO.Optimizer, outlev=3)

```


MathProgBase Interface
======================

**Note: MathProgBase works only with the old Knitro's `KTR` API.**

KNITRO.jl implements the solver-independent
[MathProgBase](https://github.com/JuliaOpt/MathProgBase.jl) interface, and so
can be used within modeling software like [JuMP](https://github.com/JuliaOpt/JuMP.jl).

The solver object is called `KnitroSolver`. All options listed in the
[Artelys Knitro documentation](https://www.artelys.com/tools/knitro_doc/3_referenceManual/userOptions.html)
may be passed directly. For example, you can run all algorithms by saying
`KnitroSolver(KTR_PARAM_ALG=KTR_ALG_MULTI)`, and here is a formulation
modelled using [JuMP.jl](https://github.com/JuliaOpt/JuMP.jl) that specifies
some non-default option settings:

```julia
using KNITRO, JuMP

## Solve test problem 1 (Synthesis of processing system) in
 #  M. Duran & I.E. Grossmann, "An outer approximation algorithm for
 #  a class of mixed integer nonlinear programs", Mathematical
 #  Programming 36, pp. 307-339, 1986.  The problem also appears as
 #  problem synthes1 in the MacMINLP test set.

m = Model(solver=KnitroSolver(mip_method = KTR_MIP_METHOD_BB,
                              algorithm = KTR_ALG_ACT_CG,
                              outmode = KTR_OUTMODE_SCREEN,
                              KTR_PARAM_OUTLEV = KTR_OUTLEV_ALL,
                              KTR_PARAM_MIP_OUTINTERVAL = 1,
                              KTR_PARAM_MIP_MAXNODES = 10000,
                              KTR_PARAM_HESSIAN_NO_F = KTR_HESSIAN_NO_F_ALLOW))
x_U = [2,2,1]
@variable(m, x_U[i] >= x[i=1:3] >= 0)
@variable(m, y[4:6], Bin)

@NLobjective(m, Min, 10 + 10*x[1] - 7*x[3] + 5*y[4] + 6*y[5] + 8*y[6] - 18*log(x[2]+1) - 19.2*log(x[1]-x[2]+1))
@NLconstraints(m, begin
    0.8*log(x[2] + 1) + 0.96*log(x[1] - x[2] + 1) - 0.8*x[3] >= 0
    log(x[2] + 1) + 1.2*log(x[1] - x[2] + 1) - x[3] - 2*y[6] >= -2
    x[2] - x[1] <= 0
    x[2] - 2*y[4] <= 0
    x[1] - x[2] - 2*y[5] <= 0
    y[4] + y[5] <= 1
end)
solve(m)
```

**NB: The MathProgBase interface is bound to be deprecated. Please use
MathOptInterface instead.**


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
