#*******************************************************/
#* Copyright(c) 2018 by Artelys                        */
#* This source code is subject to the terms of the     */
#* MIT Expat License (see LICENSE.md)                  */
#*******************************************************/

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# This example demonstrates how to use MathOptInterface and
# Knitro to solve the following # simple nonlinear optimization problem.
# This model is test problem # HS15 from the Hock & Schittkowski collection.
#
# min   100(x1 - x0^2)^2 +(1 - x0)^2
# s.t.  x0 x1 >= 1
#       x0 + x1^2 >= 0
#       x0 <= 0.5
#
# The standard start point(-2, 1) usually converges to the standard
# minimum at(0.5, 2.0), with final objective = 306.5.
# Sometimes the solver converges to another local minimum
# at(-0.79212, -1.26243), with final objective = 360.4.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


using KNITRO, MathOptInterface
using Test
const MOI = MathOptInterface

struct HS15 <: MOI.AbstractNLPEvaluator
    enable_hessian::Bool
end


MOI.features_available(d::HS15) = [:Grad]
MOI.initialize(d::HS15, features) = nothing

MOI.jacobian_structure(d::HS15) = []
#*------------------------------------------------------------------*
#*     FUNCTION callbackEvalF                                       *
#*------------------------------------------------------------------*
function MOI.eval_objective(d::HS15, x)
    return 100*(x[2] - x[1]^2)^2 + (1 - x[1])^2
end

function MOI.eval_constraint(::HS15, g, x)
    nothing
end
function MOI.eval_constraint_jacobian(::HS15, g, x)
    nothing
end

#*------------------------------------------------------------------*
#*     FUNCTION callbackEvalG                                       *
#*------------------------------------------------------------------*
function MOI.eval_objective_gradient(d::HS15, grad_f, x)
    # Evaluate gradient of nonlinear objective
    dTmp = x[2] - x[1] * x[1]
    grad_f[1] = (-400.0 * dTmp * x[1]) - (2.0 * (1.0 - x[1]))
    grad_f[2] = 200.0 * dTmp
end

#*------------------------------------------------------------------*
#*     FUNCTION callbackEvalH                                       *
#*------------------------------------------------------------------*
function MOI.eval_hessian_lagrangian(d::HS15, H, x, σ, μ)
    H[1] = σ * ((-400.0 * x[2]) + (1200.0 * x[1] * x[1]) + 2.0) #(0,0)
    H[2] = σ * (-400.0 * x[1]) #(0,1)
    H[3] = σ * 200.0           #(1,1)

    return 0
end

#*------------------------------------------------------------------*
#*     main                                                         *
#*------------------------------------------------------------------*

# Initialize Knitro
options = joinpath(dirname(@__FILE__), "..", "examples", "knitro.opt")
solver = KNITRO.Optimizer(option_file=options)
lb =[]; ub=[]
block_data = MOI.NLPBlockData(MOI.NLPBoundsPair.(lb, ub), HS15(false), true)

n = 2
v = MOI.add_variables(solver, n)

u = [0.5, KNITRO.KN_INFINITY]
start = [-2., 1.]

for i in 1:2
    MOI.add_constraint(solver, MOI.SingleVariable(v[i]), MOI.LessThan(u[i]))
    MOI.set(solver, MOI.VariablePrimalStart(), v[i], start[i])
end

# Add the constraints and set their lower bounds
m = 2
# first constraint: x0 * x1 >= 1
cf1 = MOI.ScalarQuadraticFunction{Float64}(
        MOI.ScalarAffineTerm.(0.0, v),
        [MOI.ScalarQuadraticTerm(1., v[1], v[2])],
        0.)
c1 = MOI.add_constraint(solver, cf1, MOI.GreaterThan{Float64}(1.))

# second constraint: x0 + x1^2 >= 0
cf2 = MOI.ScalarQuadraticFunction(
                                 [MOI.ScalarAffineTerm(2.0, v[1])],
                                 [MOI.ScalarQuadraticTerm(1., v[2], v[2])],
                                 0.)
c2 = MOI.add_constraint(solver, cf2, MOI.GreaterThan(0.))

MOI.set(solver, MOI.ObjectiveSense(), MOI.MIN_SENSE)
# define NLP structure
MOI.set(solver, MOI.NLPBlock(), block_data)


# Specify that the user is able to provide evaluations
# of the hessian matrix without the objective component.
# turned off by default but should be enabled if possible.
KNITRO.KN_set_param(solver.inner, KNITRO.KN_PARAM_HESSIAN_NO_F, KNITRO.KN_HESSIAN_NO_F_ALLOW)

# Perform a derivative check.
KNITRO.KN_set_param(solver.inner, KNITRO.KN_PARAM_DERIVCHECK, KNITRO.KN_DERIVCHECK_ALL)

# Solve the problem.
#
# Return status codes are defined in "knitro.h" and described
# in the Knitro manual.
MOI.optimize!(solver)

# Free solver environment properly
MOI.empty!(solver)
