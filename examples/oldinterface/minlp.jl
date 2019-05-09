using KNITRO

 ## Solve test problem 1 (Synthesis of processing system) in
 #  M. Duran & I.E. Grossmann, "An outer approximation algorithm for
 #  a class of mixed integer nonlinear programs", Mathematical
 #  Programming 36, pp. 307-339, 1986.  The problem also appears as
 #  problem synthes1 in the MacMINLP test set.
 #
 #  min   5 x4 + 6 x5 + 8 x6 + 10 x1 - 7 x3 -18 math.log(x2 + 1)
 #       - 19.2 math.log(x1 - x2 + 1) + 10
 #  s.t.  0.8 math.log(x2 + 1) + 0.96 math.log(x1 - x2 + 1) - 0.8 x3 >= 0
 #        math.log(x2 + 1) + 1.2 math.log(x1 - x2 + 1) - x3 - 2 x6 >= -2
 #        x2 - x1 <= 0
 #        x2 - 2 x4 <= 0
 #        x1 - x2 - 2 x5 <= 0
 #        x4 + x5 <= 1
 #        0 <= x1 <= 2
 #        0 <= x2 <= 2
 #        0 <= x3 <= 1
 #        x1, x2, x3 continuous
 #        x4, x5, x6 binary
 #
 #
 #  The solution is (1.30098, 0, 1, 0, 1, 0).
 ##

function eval_f(x::Vector{Float64})
    tmp1 = x[1] - x[2] + 1.0
    tmp2 = x[2] + 1.0
    linear_terms = 10.0 + 10.0*x[1] - 7.0*x[3] + 5.0*x[4] + 6.0*x[5] + 8.0*x[6]
    nonlinear_terms = - 18.0*log(tmp2) - 19.2*log(tmp1)
    linear_terms + nonlinear_terms
end

function eval_g(x::Vector{Float64}, cons::Vector{Float64})
    tmp1 = x[1] - x[2] + 1.0
    tmp2 = x[2] + 1.0
    cons[1] = 0.8*log(tmp2) + 0.96*log(tmp1) - 0.8*x[3]
    cons[2] = log(tmp2) + 1.2*log(tmp1) - x[3] - 2*x[6]
    cons[3] = x[2] - x[1]
    cons[4] = x[2] - 2*x[4]
    cons[5] = x[1] - x[2] - 2*x[5]
    cons[6] = x[4] + x[5]
end

function eval_grad_f(x::Vector{Float64}, grad::Vector{Float64})
    tmp1 = x[1] - x[2] + 1.0
    tmp2 = x[2] + 1.0
    grad[1] = 10.0 - (19.2 / tmp1)
    grad[2] = (-18.0 / tmp2) + (19.2 / tmp1)
    grad[3] = -7.0
    grad[4] = 5.0
    grad[5] = 6.0
    grad[6] = 8.0
end

function eval_jac_g(x::Vector{Float64}, jac::Vector{Float64})
    tmp1 = x[1] - x[2] + 1.0
    tmp2 = x[2] + 1.0
    #---- GRADIENT OF CONSTRAINT 0.
    jac[1] = 0.96 / tmp1
    jac[2] = (-0.96 / tmp1) + (0.8 / tmp2)
    jac[3] = -0.8
    #---- GRADIENT OF CONSTRAINT 1.
    jac[4] = 1.2 / tmp1
    jac[5] = (-1.2 / tmp1) + (1.0 / tmp2)
    jac[6] = -1.0
    jac[7] = -2.0
    #---- GRADIENT OF CONSTRAINT 2.
    jac[8] = -1.0
    jac[9] = 1.0
    #---- GRADIENT OF CONSTRAINT 3.
    jac[10] = 1.0
    jac[11] = -2.0
    #---- GRADIENT OF CONSTRAINT 4.
    jac[12] = 1.0
    jac[13] = -1.0
    jac[14] = -2.0
    #---- GRADIENT OF CONSTRAINT 5.
    jac[15] = 1.0
    jac[16] = 1.0
end

function eval_h(x::Vector{Float64}, lambda::Vector{Float64},
                sigma::Float64, hess::Vector{Float64})
    tmp1 = x[1] - x[2] + 1.0
    tmp2 = x[2] + 1.0
    hess[1] = sigma*(19.2 / (tmp1*tmp1)) + lambda[1]*(-0.96 / (tmp1*tmp1)) + lambda[2]*(-1.2 / (tmp1*tmp1))
    hess[2] = sigma*(-19.2 / (tmp1*tmp1)) + lambda[1]*(0.96 / (tmp1*tmp1)) + lambda[2]*(1.2 / (tmp1*tmp1))
    hess[3] = sigma*((19.2 / (tmp1*tmp1)) + (18.0 / (tmp2*tmp2))) + lambda[1]*((-0.96 / (tmp1*tmp1)) - (0.8 / (tmp2*tmp2))) + lambda[2]*((-1.2 / (tmp1*tmp1)) - (1.0 / (tmp2*tmp2)))
end

function eval_hv(x::Vector{Float64}, lambda::Vector{Float64},
                 sigma::Float64, hv::Vector{Float64})
    tmp1 = (x[1] - x[2] + 1.0)^2
    tmp2 = x[2] + 1.0

    hv1 = (sigma*(19.2/tmp1)+lambda[1]*(-0.96/tmp1)+lambda[2]*(-1.2/tmp1))*hv[1]
    hv1 = hv1 + (sigma*(-19.2/tmp1)+lambda[1]*(0.96/tmp1)+lambda[2]*(1.2/tmp1))*hv[2]
    hv2 = (sigma*(-19.2/tmp1)+lambda[1]*(0.96/tmp1)+lambda[2]*(1.2/tmp1))*hv[1]
    hv2 = hv2 + (sigma*((19.2/tmp1)+(18.0/tmp2))+lambda[1]*((-0.96/tmp1)-(0.8/tmp2))+lambda[2]*((-1.2/tmp1)-(1.0/tmp2)))*hv[2]
    hv[1] = hv1
    hv[2] = hv2
    hv[3] = 0.0
    hv[4] = 0.0
    hv[5] = 0.0
    hv[6] = 0.0
end

function eval_mip_node(kp::KnitroProblem, obj::Float64)
    # Print information about the status of the MIP solution
    println("callbackProcessNode:")
    println("    Node number    = ", get_mip_num_nodes(kp))
    println("    Node objective = ", obj)
    println("    Current relaxation bound = ", get_mip_relaxation_bnd(kp))
    bound = get_mip_incumbent_obj(kp)
    if abs(bound) >= KTR_INFBOUND
        println("    No integer feasible point found yet.")
    else
        println("    Current incumbent bound  = ", bound)
        println("    Absolute integrality gap = ", get_mip_abs_gap(kp))
        println("    Relative integrality gap = ", get_mip_rel_gap(kp))
    end
end

objType = KTR_OBJTYPE_GENERAL
objGoal = KTR_OBJGOAL_MINIMIZE
objFnType = KTR_FNTYPE_CONVEX

n = 6
x_L = zeros(n)
x_U = [2.0,2.0,1.0,1.0,1.0,1.0]

m = 6
c_Type = [KTR_CONTYPE_GENERAL,
          KTR_CONTYPE_GENERAL,
          KTR_CONTYPE_LINEAR,
          KTR_CONTYPE_LINEAR,
          KTR_CONTYPE_LINEAR,
          KTR_CONTYPE_LINEAR]
c_FnType = [KTR_FNTYPE_CONVEX,
           KTR_FNTYPE_CONVEX,
           KTR_FNTYPE_CONVEX,
           KTR_FNTYPE_CONVEX,
           KTR_FNTYPE_CONVEX,
           KTR_FNTYPE_CONVEX]
c_L = [0.0,-2.0,
       -KTR_INFBOUND,
       -KTR_INFBOUND,
       -KTR_INFBOUND,
       -KTR_INFBOUND]
c_U = [KTR_INFBOUND,
       KTR_INFBOUND,
       0.0,0.0,0.0,1.0]

jac_con = Int32[0,0,0,1,1,1,1,2,2,3,3,4,4,4,5,5]
jac_var = Int32[0,1,2,0,1,2,5,0,1,1,3,0,1,4,3,4]
hess_row = Int32[0,0,1]
hess_col = Int32[0,1,1]

x_Type = [KTR_VARTYPE_CONTINUOUS,
          KTR_VARTYPE_CONTINUOUS,
          KTR_VARTYPE_CONTINUOUS,
          KTR_VARTYPE_BINARY,
          KTR_VARTYPE_BINARY,
          KTR_VARTYPE_BINARY]

kp = createProblem()
@test applicationReturnStatus(kp) == :Uninitialized

# ------ Illustrate how to override default options ------
# --- (options must be set before calling init_problem) ---
setOption(kp, "mip_method", KTR_MIP_METHOD_BB)
setOption(kp, "algorithm", KTR_ALG_ACT_CG)
setOption(kp, "outmode", KTR_OUTMODE_SCREEN)
setOption(kp, KTR_PARAM_OUTLEV, KTR_OUTLEV_ALL)
setOption(kp, KTR_PARAM_MIP_OUTINTERVAL, 1)
setOption(kp, KTR_PARAM_MIP_MAXNODES, 10000)
# specify that user is able to provide evaluations of the
# hessian matrix without the objective component
# (turned off by default, but should be enabled if possible)
setOption(kp, KTR_PARAM_HESSIAN_NO_F, KTR_HESSIAN_NO_F_ALLOW)
@test applicationReturnStatus(kp) == :Uninitialized

# --- set callback functions ---
setCallbacks(kp, eval_f, eval_g, eval_grad_f, eval_jac_g, eval_h, eval_hv)
@test applicationReturnStatus(kp) == :Uninitialized
setMIPCallback(kp, eval_mip_node)
@test applicationReturnStatus(kp) == :Uninitialized

initializeProblem(kp, objGoal, objType, objFnType,
                  x_Type, x_L, x_U, c_Type, c_FnType, c_L, c_U,
                  jac_var, jac_con, hess_row, hess_col)
@test applicationReturnStatus(kp) == :Initialized
solveProblem(kp)

# --- test optimal solutions ---
@testset "Test optimal solutions" begin
    @test applicationReturnStatus(kp) == :Optimal
    @test isapprox(kp.x, [1.30098, 0.0, 1.0, 0.0, 1.0, 0.0], atol=1e-5)
end

freeProblem(kp)
