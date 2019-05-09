using KNITRO

#    min  9 - 8x1 - 6x2 - 4x3
#         + 2(x1^2) + 2(x2^2) + (x3^2) + 2(x1*x2) + 2(x1*x3)
#    subject to  c[0]:  x1 + x2 + 2x3 <= 3
#                x1 >= 0
#                x2 >= 0
#                x3 >= 0
#    initpt (0.5, 0.5, 0.5)
#
#    Solution is x1=4/3, x2=7/9, x3=4/9, lambda=2/9  (f* = 1/9)
#
#  The problem comes from Hock and Schittkowski, HS35.

function eval_f(x::Vector{Float64})
    linear_terms = 9.0 - 8.0*x[1] - 6.0*x[2] - 4.0*x[3]
    quad_terms = 2.0*x[1]^2 + 2.0*x[2]^2 + x[3]^2 + 2.0*x[1]*x[2] + 2.0*x[1]*x[3]
    return linear_terms + quad_terms
end

function eval_g(x::Vector{Float64}, cons::Vector{Float64})
    cons[1] = x[1] + x[2] + 2.0*x[3]
end

function eval_grad_f(x::Vector{Float64}, grad::Vector{Float64})
    grad[1] = -8.0 + 4.0*x[1] + 2.0*x[2] + 2.0*x[3]
    grad[2] = -6.0 + 2.0*x[1] + 4.0*x[2]
    grad[3] = -4.0 + 2.0*x[1]            + 2.0*x[3]
end

function eval_jac_g(x::Vector{Float64}, jac::Vector{Float64})
    jac[1] = 1.0
    jac[2] = 1.0
    jac[3] = 2.0
end

function eval_h(x::Vector{Float64}, lambda::Vector{Float64},
                sigma::Float64, hess::Vector{Float64})
    hess[1] = sigma*4.0
    hess[2] = sigma*2.0
    hess[3] = sigma*2.0
    hess[4] = sigma*4.0
    hess[5] = sigma*2.0
end

function eval_hv(x::Vector{Float64}, lambda::Vector{Float64},
                 sigma::Float64, hv::Vector{Float64})
    hv[1] = sigma*4.0*hv[1] + sigma*2.0*hv[2] + sigma*2.0*hv[3]
    hv[2] = sigma*2.0*hv[1] + sigma*4.0*hv[2]
    hv[3] = sigma*2.0*hv[1]                   + sigma*2.0*hv[3]
end

objGoal = KTR_OBJGOAL_MINIMIZE
objType = KTR_OBJTYPE_QUADRATIC

n = 3
x_L = zeros(n)
x_U = [KTR_INFBOUND,KTR_INFBOUND,KTR_INFBOUND]

m = 1
c_Type = [KTR_CONTYPE_LINEAR]
c_L = [-KTR_INFBOUND]
c_U = [3.0]

jac_con = Int32[0,0,0]
jac_var = Int32[0,1,2]
hess_row = Int32[0,0,0,1,2]
hess_col = Int32[0,1,2,1,2]

x       = [0.5,0.5,0.5]
lambda  = zeros(n+m)
obj     = [0.0]

kp = createProblem()
@test applicationReturnStatus(kp) == :Uninitialized
loadOptionsFile(kp,joinpath(dirname(@__FILE__),"knitro.opt"))
@test applicationReturnStatus(kp) == :Uninitialized

# --- test getters and setters ---
hessopt = zeros(Int32, 1)
getOption(kp, "hessopt", hessopt)
# ---------------------------------

initializeProblem(kp, objGoal, objType, x_L, x_U, c_Type, c_L, c_U,
                  jac_var, jac_con, hess_row, hess_col)
@test applicationReturnStatus(kp) == :Initialized
setCallbacks(kp, eval_f, eval_g, eval_grad_f, eval_jac_g, eval_h, eval_hv)
@test applicationReturnStatus(kp) == :Initialized
solveProblem(kp)

# --- test optimal solutions ---
@testset "Test optimal solutions" begin
    @test applicationReturnStatus(kp) == :Optimal
    @test isapprox(kp.x, [1.3333333, 0.7777777, 0.4444444], atol=1e-5)
    @test isapprox(kp.obj_val[1], 0.1111111, atol=1e-5)
end

@testset "Test getters" begin
    @test get_number_FC_evals(kp) >= 0
    @test get_number_GA_evals(kp) >= 0
    @test get_number_H_evals(kp) >= 0
    @test get_number_HV_evals(kp) >= 0
    @test get_number_iters(kp) >= 0
    @test get_number_cg_iters(kp) >= 0
    @test isapprox(get_abs_feas_error(kp), 0.0, atol=1e-5)
    @test isapprox(get_rel_feas_error(kp), 0.0, atol=1e-5)
    @test isapprox(get_abs_opt_error(kp), 0.0, atol=1e-5)
    @test isapprox(get_rel_opt_error(kp), 0.0, atol=1e-5)
end

# start at a different starting point
x = [2.0,2.0,2.0]
lambda = ones(n+m)
restartProblem(kp, x, lambda)
@test applicationReturnStatus(kp) == :Initialized
solveProblem(kp)
@testset "Test optimal solutions (at a different starting point)" begin
    @test applicationReturnStatus(kp) == :Optimal
    @test isapprox(kp.x,  [1.3333333, 0.7777777, 0.4444444], atol=1e-5)
    @test isapprox(kp.obj_val[1], 0.1111111, atol=1e-5)
end

freeProblem(kp)
