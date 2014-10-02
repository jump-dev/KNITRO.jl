using Knitro
using Base.Test

 ## Solve a small QCQP (quadratically constrained quadratic programming)
 #  test problem.
 #
 #  min   1000 - x0^2 - 2 x1^2 - x2^2 - x0 x1 - x0 x2
 #  s.t.  8 x0 + 14 x1 + 7 x2 - 56 = 0
 #        x0^2 + x1^2 + x2^2 - 25 >= 0
 #        x0 >= 0, x1 >= 0, x2 >= 0
 #
 #  The start point (2, 2, 2) converges to the minimum at (0, 0, 8),
 #  with final objective = 936.0.  From a different start point,
 #  KNITRO may converge to an alternate local solution at (7, 0, 0),
 #  with objective = 951.0.
 ##

function eval_f(x::Vector{Float64})
  1000.0 - x[1]^2 - 2.0*x[2]^2 - x[3]^2 - x[1]^2 - x[1]*x[3]
end

function eval_g(x::Vector{Float64}, cons::Vector{Float64})
  cons[1] = 8.0*x[1] + 14.0*x[2] + 7.0*x[3] - 56.0
  cons[2] = x[1]^2 + x[2]^2 + x[3]^2 - 25.0
end

function eval_grad_f(x::Vector{Float64}, grad::Vector{Float64})
  grad[1] = -2.0*x[1] - x[2] - x[3]
  grad[2] = -4.0*x[2] - x[1]
  grad[3] = -2.0*x[3] - x[1]
end

function eval_jac_g(x::Vector{Float64}, jac::Vector{Float64})
    #---- GRADIENT OF THE FIRST CONSTRAINT, c[0].
    jac[1] =  8.0
    jac[2] = 14.0
    jac[3] =  7.0
        
    #---- GRADIENT OF THE SECOND CONSTRAINT, c[1].
    jac[4] = 2.0*x[1]
    jac[5] = 2.0*x[2]
    jac[6] = 2.0*x[3]
end

function eval_h(x::Vector{Float64}, lambda::Vector{Float64},
                sigma::Float64, hess::Vector{Float64})
  hess[1] = -2.0*sigma + 2.0*lambda[2]
  hess[2] = -1.0*sigma
  hess[3] = -1.0*sigma
  hess[4] = -4.0*sigma + 2.0*lambda[2]
  hess[5] = -2.0*sigma + 2.0*lambda[2]
end

function eval_hv(x::Vector{Float64}, lambda::Vector{Float64},
                 sigma::Float64, hv::Vector{Float64})
  hv1 = (-2.0*sigma + 2.0*lambda[2])*hv[1] - sigma*hv[2] - sigma*hv[3]
  hv2 = -sigma*hv[1] + (-4.0*sigma + 2.0*lambda[2])*hv[2]
  hv3 = -sigma*hv[1] + (-2.0*sigma + 2.0*lambda[2])*hv[3]
  hv[1] = hv1
  hv[2] = hv2
  hv[3] = hv3
end

objGoal = KTR_OBJGOAL_MINIMIZE
objType = KTR_OBJTYPE_QUADRATIC

n = 3
x_L = zeros(3)
x_U = fill(KTR_INFBOUND, 3)
x = [-2.0,1.0] # initial guess

m = 2
c_Type = [KTR_CONTYPE_LINEAR, KTR_CONTYPE_QUADRATIC]
c_L = zeros(2)
c_U = [0.0, KTR_INFBOUND]

jac_con = Int32[0,0,0,1,1,1]
jac_var = Int32[0,1,2,0,1,2]
hess_row = Int32[0,0,0,1,2]
hess_col = Int32[0,1,2,1,2]

x = [2.0,2.0,2.0] # initial guess

kp = createProblem()
set_param(kp, "outlev", "all")
set_param(kp, "hessopt", int32(1))
set_param(kp, "hessian_no_f", int32(1))
set_param(kp, "feastol", 1.0e-10)

ret = init_problem(kp, objGoal, objType,
                   x_L, x_U, c_Type, c_L, c_U,
                   jac_var, jac_con, hess_row, hess_col; initial_x=x)

# setCallbacks(kp, eval_f, eval_g, eval_grad_f, eval_jac_g, eval_h, eval_hv)

#---- ALLOCATE ARRAYS FOR REVERSE COMMUNICATIONS OPERATION.
lambda = Array(Float64, m+n)
obj = Array(Float64, 1)
cons = Array(Float64, m)
objGrad = Array(Float64, n)
jac = Array(Float64, length(jac_con))
hess = Array(Float64, length(hess_row))
hessVector = Array(Float64, n)

#---- SOLVE THE PROBLEM.  IN REVERSE COMMUNICATIONS MODE, KNITRO
#---- RETURNS WHENEVER IT NEEDS MORE PROBLEM INFORMATION.  THE CALLING
#---- PROGRAM MUST INTERPRET KNITRO'S RETURN STATUS AND CONTINUE
#---- SUPPLYING PROBLEM INFORMATION UNTIL KNITRO IS COMPLETE.
nEvalStatus = int32(0)
nKnStatus = int32(1)
while nKnStatus > 0
  nKnStatus = solve_problem(kp, x, lambda, nEvalStatus, obj, cons, objGrad,
                            jac, hess, hessVector)
  if nKnStatus == KTR_RC_EVALFC
    #---- KNITRO WANTS obj AND c EVALUATED AT THE POINT x.
    obj[1] = eval_f(x)
    eval_g(x,cons)
  elseif nKnStatus == KTR_RC_EVALGA
    #---- KNITRO WANTS objGrad AND jac EVALUATED AT THE POINT x.
    eval_grad_f(x, objGrad)
    eval_jac_g(x, jac)
  elseif nKnStatus == KTR_RC_EVALH
    #---- KNITRO WANTS hess EVALUATED AT THE POINT x.
    eval_h(x, lambda, 1.0, hess)
  elseif nKnStatus == KTR_RC_EVALH_NO_F
    #---- KNITRO WANTS hess EVALUATED AT THE POINT x
    #---- WITHOUT OBJECTIVE COMPONENT.
    eval_h(x, lambda, 0.0, hess)
  end
  #---- ASSUME THAT PROBLEM EVALUATION IS ALWAYS SUCCESSFUL.
  #---- IF A FUNCTION OR ITS DERIVATIVE COULD NOT BE EVALUATED
  #---- AT THE GIVEN (x, lambda), THEN SET nEvalStatus = 1 BEFORE
  #---- CALLING solve AGAIN.
  nEvalStatus = int32(0)
end

#  The start point (2, 2, 2) converges to the minimum at (0, 0, 8),
 #  with final objective = 936.0.  From a different start point,
# --- test optimal solutions ---
@test_approx_eq_eps x[1] 0.0 1e-5
@test_approx_eq_eps x[2] 0.0 1e-5
@test_approx_eq_eps x[3] 8.0 1e-5
@test_approx_eq_eps obj[1] 936.0 1e-5