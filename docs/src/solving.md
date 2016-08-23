## Creating and Solving Problems

The problem is solved by calling `solveProblem`.  Applications must provide a means of evaluating the nonlinear objective, constraints, first derivatives, and (optionally) second derivatives.  (First derivatives are also optional, but highly recommended.)

### Typical Setup
The typical calling sequence is:

```julia
kp = createProblem()
setOption(kp, ...) (set any number of parameters)
initializeProblem(kp, ...)
setCallbacks(kp, ...)
solveProblem(kp) (a single call, or a reverse communications loop)
```

### Restarting the Problem
Calling sequence if the same problem is to be solved again, with different parameters or a different start point (see `examples/hs035_restart.jl`):

```julia
kp = createProblem()
setOption(kp, ...) (set any number of parameters)
initializeProblem(kp, ...)
setCallbacks(kp, ...)
solveProblem(kp) (a single call, or a reverse communications loop)
restartProblem(kp, ...)
setOption(kp, ...) (set any number of parameters)
solveProblem(kp) (a single call, or a reverse communications loop)
```

For MIP problems, use `mip_init_problem` and `mip_solve` instead (see `examples/minlp.jl`).

### Reverse Communications
If the application provides callback functions for making evaluations, then a single call to `solveProblem` will return the solution. Alternatively, the application can employ a reverse communications driver, with the following calling sequence:

```julia
kp = createProblem()
setOption(kp, ...) (set any number of parameters)
initializeProblem(kp, ...)
while status != Optimal
    status = solveProblem(kp, ...)
    [...]
end
```

In this case, `solveProblem` returns a status code whenever it needs evaluation data (see `examples/qcqp_reversecomm.jl`).