KNITRO.jl
=========
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://juliaopt.github.io/KNITRO.jl/latest)

The KNITRO.jl package provides an interface for using the [Artelys Knitro solver](http://artelys.com/en/optimization-tools/knitro) from [Julia](http://julialang.org/). You cannot use KNITRO.jl without having purchased and installed a copy of Knitro from [Artelys](http://artelys.com/). This package is available free of charge and in no way replaces or alters any functionality of Artelys Knitro solver.

Artelys Knitro functionality is extensive, so coverage is incomplete, but most functionality for solving linear, nonlinear, and mixed-integer programs is provided. Documentation is available at [https://juliaopt.github.io/KNITRO.jl/latest](https://juliaopt.github.io/KNITRO.jl/latest).

*The Artelys Knitro wrapper for Julia is community driven and not officially supported by Artelys. If you are an Artelys customer interested in official support for Julia, let them know!*

MathProgBase Interface
======================

KNITRO.jl implements the solver-independent [MathProgBase](https://github.com/JuliaOpt/MathProgBase.jl) interface, and so can be used within modeling software like [JuMP](https://github.com/JuliaOpt/JuMP.jl). 

The solver object is called `KnitroSolver`. All options listed in the [Artelys Knitro documentation](https://www.artelys.com/tools/knitro_doc/3_referenceManual/userOptions.html) may be passed directly. For example, you can run all algorithms by saying `KnitroSolver(KTR_PARAM_ALG=KTR_ALG_MULTI)`, and here is a formulation modelled using [JuMP.jl](https://github.com/JuliaOpt/JuMP.jl) that specifies some non-default option settings:

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
