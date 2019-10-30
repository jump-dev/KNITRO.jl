# Test calling Knitro with license manager

using KNITRO, JuMP
using Test
using MathOptInterface
const MOI = MathOptInterface

# hs071
# Polynomial objective and constraints
# min x1 * x4 * (x1 + x2 + x3) + x3
# st  x1 * x2 * x3 * x4 >= 25
#     x1^2 + x2^2 + x3^2 + x4^2 = 40
#     1 <= x1, x2, x3, x4 <= 5
# Start at (1,5,5,1)
# End at (1.000..., 4.743..., 3.821..., 1.379...)

# Instantiate license manager
lm = KNITRO.LMcontext()

nruns = 10

for i in 1:nruns
    model = Model(with_optimizer(KNITRO.Optimizer, license_manager=lm, outlev=1))

    initval = [1, 5, 5, 1]

    @variable(model, 1 <= x[i=1:4] <= 5, start=initval[i])
    @NLobjective(model, Min, x[1] * x[4] * (x[1] + x[2] + x[3]) + x[3])
    c1 = @NLconstraint(model, x[1] * x[2] * x[3] * x[4] >= 25)
    c2 = @NLconstraint(model, sum(x[i]^2 for i=1:4) == 40)

    JuMP.optimize!(model)
    @test JuMP.termination_status(model) == MOI.LOCALLY_SOLVED

    # Warning! Free Knitro model before freeing license manager!
    MOI.empty!(backend(model))
end

# Free license manager
KNITRO.KN_release_license(lm)
