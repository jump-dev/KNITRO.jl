You can also work with Artelys Knitro through [JuMP.jl](http://jump.readthedocs.org/en/latest/), a domain-specific modeling language for mathematical programming embedded in Julia.

Re-visiting the earlier example, here's what it'll look like with JuMP:

```julia
using KNITRO, JuMP
m = JuMP.Model(solver=KNITRO.KnitroSolver(options_file="knitro.opt"))
JuMP.@variable(m, x[1:3]>=0)
JuMP.@objective(m, Min, 9.0 - 8.0*x[1] - 6.0*x[2] - 4.0*x[3]
                            + 2.0*x[1]^2 + 2.0*x[2]^2 + x[3]^2
                            + 2.0*x[1]*x[2] + 2.0*x[1]*x[3])
JuMP.@constraint(m, x[1] + x[2] + 2.0*x[3] <= 3)
JuMP.solve(m)
```

**Remark**: To use Artelys Knitro through the JuMP interface, you currently need
to have a nonlinear objective (via `@NLobjective`) or at least one nonlinear
constraint (via `@NLconstraint`).

### Solver Parameters
You can also provide solver parameters to Artelys Knitro through JuMP, e.g.

```julia
KnitroSolver() # default parameters
KnitroSolver(KTR_PARAM_ALG=5)
KnitroSolver(hessopt=1)
```

You can also provide the path to the options, or tuner, using the `options_file`
or `tuner_file` keywords respectively, e.g.

```julia
KnitroSolver(options_file="tuner-fixed.opt")
KnitroSolver(tuner_file="tuner-explore.opt")
```
