#*******************************************************/
#* Copyright(c) 2018 by Artelys                        */
#* This source code is subject to the terms of the     */
#* MIT Expat License (see LICENSE.md)                  */
#*******************************************************/

#*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#*  This example demonstrates how to use Knitro to solve the following
#*  simple problem with a second order cone constraint.
#*
#*  min   x2-1 + x0^2 + x1^2 +(x2+x3)^2
#*  s.t.  sqrt(x0^2 +(2*x2)^2)  - 10*x1 <= 0 (c0)
#*        x3^2 + 5*x0 <= 100                  (c1)
#*        2*x1 + 3*x2 <= 100                  (c2)
#*        x2 <= 1, x1 >= 1, x3 >= 2
#*
#*  Note that the first constraint c0 is a second order cone
#*  constraint that can be written in the form: ||Ax+b||<=c'x
#*  where A = [1, 0, 0, 0 , (b is empty).
#*             0, 0, 2, 0]
#*
#*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

using KNITRO


#** Create a new Knitro solver instance. */
kc = KNITRO.KN_new()

#** Initialize Knitro with the problem definition. */

####Add the variables and set their bounds.
####*  Note: any unset lower bounds are assumed to be
####*  unbounded below and any unset upper bounds are
####*  assumed to be unbounded above. */
n = 4;
KNITRO.KN_add_vars(kc, n)

xLoBnds = [-KNITRO.KN_INFINITY, 1.0, -KNITRO.KN_INFINITY, 2.0]
xUpBnds = [KNITRO.KN_INFINITY, KNITRO.KN_INFINITY, 1.0, KNITRO.KN_INFINITY]
KNITRO.KN_set_var_lobnds(kc, xLoBnds)
KNITRO.KN_set_var_upbnds(kc, xUpBnds)

#** Add the constraints and set the RHS and coefficients */
m = 3;
KNITRO.KN_add_cons(kc, m)
KNITRO.KN_set_con_upbnd(kc, 0, 0.0)
KNITRO.KN_set_con_upbnd(kc, 1, 100.0)
KNITRO.KN_set_con_upbnd(kc, 2, 100.0)

#** coefficients for linear terms in constraint c2 */
indexVars1 = Cint[1, 2]
coefs1 = [2.0, 3.0]
KNITRO.KN_add_con_linear_struct(kc, 2, indexVars1, coefs1)

#** coefficient for linear term in constraint c1 */
indexVars2 = Cint[0]
coefs2 = [5.0]
KNITRO.KN_add_con_linear_struct(kc, 1, indexVars2, coefs2)

#** coefficient for linear term in constraint c0 */
indexVars3 = Cint[1]
coefs3 = [-10.]
KNITRO.KN_add_con_linear_struct(kc, 0, indexVars3, coefs3)

#** coefficient for quadratic term in constraint c1 */
qconIndexVar1 = 3;
qconIndexVar2 = 3;
qconCoef = 1.0;
KNITRO.KN_add_con_quadratic_struct(kc, 1, qconIndexVar1, qconIndexVar2, qconCoef)

#** Coefficients for L2-norm constraint components in c0.
#*  Assume the form ||Ax+b|| (here with b = 0)
dimA = 2;   # A = [1, 0, 0, 0; 0, 0, 2, 0] has two rows */
nnzA = 2;
indexRowsA = Cint[0, 1]
indexVarsA = Cint[0, 2]
coefsA = [1., 2.]
b = [0., 0.]
KNITRO.KN_add_con_L2norm(kc, 0, dimA, nnzA, indexRowsA, indexVarsA, coefsA, b)

#* Set minimize or maximize(if not set, assumed minimize) */
KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MINIMIZE)

#** Add constant value to the objective. */
KNITRO.KN_add_obj_constant(kc, -1.0)

#** Set quadratic objective structure.
#*  Note:(x2 + x3)^2 = x2^2 + 2*x2*x3 + x3^2 */
qobjIndexVars1 = Cint[0, 2, 3, 2, 1]
qobjIndexVars2 = Cint[0, 2, 3, 3, 1]
qobjCoefs = [1., 1., 1., 2., 1.]
KNITRO.KN_add_obj_quadratic_struct(kc, qobjIndexVars1, qobjIndexVars2, qobjCoefs)

#** Add linear objective term. */
lobjIndexVar = Cint[2]
lobjCoef = [1.0]
KNITRO.KN_add_obj_linear_struct(kc, lobjIndexVar, lobjCoef)

#** Interior/Direct algorithm is required for models with
#*  L2 norm structure.
KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_ALGORITHM, KNITRO.KN_ALG_BAR_DIRECT)
#** Enable the special barrier tools for second order cone(SOC) constraints. */
KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_BAR_CONIC_ENABLE, KNITRO.KN_BAR_CONIC_ENABLE_SOC)
#** Specify maximum output */
KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_OUTLEV, KNITRO.KN_OUTLEV_ALL)
#** Specify special barrier update rule */
KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_BAR_MURULE, KNITRO.KN_BAR_MURULE_FULLMPC)

#** Solve the problem.
####*
####*  Return status codes are defined in "knitro.h" and described
####*  in the Knitro manual. */
nStatus = KNITRO.KN_solve(kc)

println("Knitro converged with final status = ", nStatus)

#** An example of obtaining solution information. */
nStatus, objSol, x, _ = KNITRO.KN_get_solution(kc)
println("  optimal objective value  = ", objSol)
println("  optimal primal values x  = ", x)

feasError = KNITRO.KN_get_abs_feas_error(kc)
println("  feasibility violation    = ", feasError)
optError = KNITRO.KN_get_abs_opt_error(kc)
println("  KKT optimality violation = ", optError)

#** Delete the Knitro solver instance. */
KNITRO.KN_free(kc)
