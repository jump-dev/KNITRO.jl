using KNITRO

 ## Solve test problem HS15 from the Hock & Schittkowski collection.
 #
 #  min   100 (x2 - x1^2)^2 + (1 - x1)^2
 #  s.t.  x1 x2 >= 1
 #        x1 + x2^2 >= 0
 #        x1 <= 0.5
 #
 #  The standard start point (-2, 1) usually converges to the standard
 #  minimum at (0.5, 2.0), with final objective = 306.5.
 #  Sometimes the solver converges to another local minimum
 #  at (-0.79212, -1.26243), with final objective = 360.4.
 ##

function eval_f(x::Vector{Float64})
    tmp = x[2] - x[1]^2
    100.0*tmp*tmp + (1.0-x[1])^2
end

function eval_g(x::Vector{Float64}, cons::Vector{Float64})
    cons[1] = x[1] * x[2]
    cons[2] = x[1] + x[2]^2
end

function eval_grad_f(x::Vector{Float64}, grad::Vector{Float64})
    tmp = x[2] - x[1]^2
    grad[1] = (-400.0 * tmp * x[1]) - (2.0 * (1.0 - x[1]))
    grad[2] = 200.0 * tmp
end

function eval_jac_g(x::Vector{Float64}, jac::Vector{Float64})
    jac[1] = x[2]
    jac[2] = x[1]
    jac[3] = 1.0
    jac[4] = 2.0 * x[2]
end

function eval_h(x::Vector{Float64}, lambda::Vector{Float64},
                sigma::Float64, hess::Vector{Float64})
    hess[1] = sigma * ( (-400.0 * x[2]) + (1200.0 * x[1]*x[1]) + 2.0)
    hess[2] = (sigma * (-400.0 * x[1])) + lambda[1]
    hess[3] = (sigma * 200.0) + (lambda[2] * 2.0)
end

function eval_hv(x::Vector{Float64}, lambda::Vector{Float64},
                 sigma::Float64, hv::Vector{Float64})
    # H[0,0]*v[0] + H[0,1]*v[1]
    hv1 = (sigma*(((-400.0*x[2])+(1200.0*x[1]*x[1])+2.0)))*hv[1]+(sigma*(-400.0*x[1])+lambda[1])*hv[2]
    # H[1,0]*v[0] + H[1,1]*v[1]
    hv2 = (sigma*(-400.0*x[1])+lambda[1])*hv[1]+(sigma*200.0+(lambda[2]*2.0))*hv[2]
    hv[1] = hv1
    hv[2] = hv2
end

objGoal = KTR_OBJGOAL_MINIMIZE
objType = KTR_OBJTYPE_GENERAL

n = 2
x_L = [-KTR_INFBOUND, -KTR_INFBOUND]
x_U = [0.5, KTR_INFBOUND]
x = [-2.0,1.0] # initial guess

m = 2
c_Type = [KTR_CONTYPE_QUADRATIC, KTR_CONTYPE_QUADRATIC]
c_L = [1.0, 0.0]
c_U = [KTR_INFBOUND, KTR_INFBOUND]

jac_con = Int32[0,0,1,1]
jac_var = Int32[0,1,0,1]
hess_row = Int32[0,0,1]
hess_col = Int32[0,1,1]

kp = createProblem()
@test applicationReturnStatus(kp) == :Uninitialized
loadOptionsFile(kp, joinpath(dirname(@__FILE__),"tuner-fixed.opt"))
setOption(kp, KTR_PARAM_TUNER, KTR_TUNER_ON)
loadTunerFile(kp, joinpath(dirname(@__FILE__), "tuner-explore.opt"))

initializeProblem(kp, objGoal, objType, x_L, x_U, c_Type, c_L, c_U,
                  jac_var, jac_con, hess_row, hess_col; initial_x = x)
@test applicationReturnStatus(kp) == :Initialized
setCallbacks(kp, eval_f, eval_g, eval_grad_f, eval_jac_g, eval_h, eval_hv)
solveProblem(kp)

# --- test optimal solutions ---
@testset "Test optimal solutions" begin
    @test applicationReturnStatus(kp) == :Optimal
    @test (abs(kp.x[1]-0.5) < 1e-4 || abs(kp.x[1]+0.79212) < 1e-4)
    @test (abs(kp.x[2]-2.0) < 1e-4 || abs(kp.x[2]+1.26243) < 1e-4)
    @test (abs(kp.obj_val[1]-306.5) < 0.025 || abs(kp.obj_val[1]-360.4) < 0.025)
end

freeProblem(kp)
