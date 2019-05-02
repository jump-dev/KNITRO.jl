#*******************************************************/
#* Copyright(c) 2018 by Artelys                        */
#* This source code is subject to the terms of the     */
#* MIT Expat License (see LICENSE.md)                  */
#*******************************************************/

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# This example demonstrates how to use Knitro to solve the following
# nonlinear optimization problem in the simplest way possible,
# without providing any derivative information.  If at all possible,
# derivative information should be provided as it will greatly
# improve the performance of Knitro.  See exampleNLP1.c to see the
# same model solved with the derivatives provided.
#
# This model is test problem HS15 from the Hock & Schittkowski
# collection.
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


using KNITRO, Test

#*------------------------------------------------------------------*
#*     FUNCTION callbackEvalF                                       *
#*------------------------------------------------------------------*
# The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
# Only "obj" is set in the KNITRO.KN_eval_result structure.
function callbackEvalF(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x

    # Evaluate nonlinear objective
    dTmp = x[2] - x[1] * x[1]
    evalResult.obj[1] = 100.0 * (dTmp * dTmp) + ((1.0 - x[1]) * (1.0 - x[1]))

    return 0
end

#*------------------------------------------------------------------*
#*     main                                                         *
#*------------------------------------------------------------------*

# Create a new Knitro solver instance.
kc = KNITRO.KN_new()

# Illustrate how to override default options by reading from
# the knitro.opt file.
options = joinpath(dirname(@__FILE__), "..", "examples", "knitro.opt")
KNITRO.KN_load_param_file(kc, options)

# Initialize Knitro with the problem definition.

# Add the variables and set their bounds.
# Note: any unset lower bounds are assumed to be
# unbounded below and any unset upper bounds are
# assumed to be unbounded above.
n = 2
KNITRO.KN_add_vars(kc, n)
KNITRO.KN_set_var_lobnds(kc, [-KNITRO.KN_INFINITY, -KNITRO.KN_INFINITY]) # not necessary since infinite
KNITRO.KN_set_var_upbnds(kc, [0.5, KNITRO.KN_INFINITY])
# Define an initial point. If not set, Knitro will generate one.
KNITRO.KN_set_var_primal_init_values(kc, [-2.0, 1.0])

# Add the constraints and set their lower bounds
m = 2
KNITRO.KN_add_cons(kc, m)
KNITRO.KN_set_con_lobnds(kc, [1.0, 0.0])

# Both constraints are quadratic so we can directly load all the
# structure for these constraints.

# First load quadratic structure x0*x1 for the first constraint
KNITRO.KN_add_con_quadratic_struct(kc, 0, 0, 1, 1.0)

# Load structure for the second constraint.  below we add the linear
# structure and the quadratic structure separately, though it
# is possible to add both together in one call to
# "KNITRO.KN_add_con_quadratic_struct()" since this api function also
# supports adding linear terms.

# Add linear term x0 in the second constraint
indexVar1 = 0
coef = 1.0
KNITRO.KN_add_con_linear_struct(kc, 1, 0, 1.0)

# Add quadratic term x1^2 in the second constraint
indexVar1 = 1
indexVar2 = 1
coef = 1.0
KNITRO.KN_add_con_quadratic_struct(kc, 1, 1, 1, 1.0)


# Add a callback function "callbackEvalF" to evaluate the nonlinear
#(non-quadratic) objective.  Note that the linear and
# quadratic terms in the objective could be loaded separately
# via "KNITRO.KN_add_obj_linear_struct()" / "KNITRO.KN_add_obj_quadratic_struct()".
# However, for simplicity, we evaluate the whole objective
# function through the callback.
cb = KNITRO.KN_add_objective_callback(kc, callbackEvalF)

# Set minimize or maximize(if not set, assumed minimize)
KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MINIMIZE)

# Set the non-default SQP algorithm, which typically converges in the
# fewest number of function evaluations.  This algorithm(or the
# active-set algorithm("KNITRO.KN_ALG_ACT_CG") may be preferable for
# derivative-free optimization models with expensive function
# evaluations.
KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_ALGORITHM, KNITRO.KN_ALG_ACT_SQP)

# Solve the problem.
#
# Return status codes are defined in "knitro.h" and described
# in the Knitro manual.
nStatus = KNITRO.KN_solve(kc)

# An example of obtaining solution information.
nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
println("Optimal objective value  = ", objSol)
println("Optimal x(with corresponding multiplier)")
for i in 1:n
    println("  x[$i] = ", x[i], "(lambda = ",  lambda_[m+i], ")")
end
println("Optimal constraint values(with corresponding multiplier)")
c = KNITRO.KN_get_con_values(kc)
for j in 1:m
    println("  c[$j] = ", c[j], "(lambda = ",  lambda_[j], ")")
end
println("  feasibility violation    = ", KNITRO.KN_get_abs_feas_error(kc))
println("  KKT optimality violation = ", KNITRO.KN_get_abs_opt_error(kc))

# Delete the Knitro solver instance.
KNITRO.KN_free(kc)


@testset "Exemple HS15 nlp1noderivs" begin
    @test nStatus == 0
    @test objSol  ≈ 306.5
    @test x ≈ [0.5, 2]
end
