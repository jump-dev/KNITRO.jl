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

objGoal = KTR_OBJGOAL_MINIMIZE
objType = KTR_OBJTYPE_QUADRATIC

n = 3
x_L = zeros(n)
x_U = [KTR_INFBOUND,KTR_INFBOUND,
KTR_INFBOUND]

m = 1
c_Type = [KTR_CONTYPE_LINEAR]
c_L = [-KTR_INFBOUND]
c_U = [3.0]

jac_con = Int32[0,0,0]
jac_var = Int32[0,1,2]

x       = [0.5,0.5,0.5]
lambda  = zeros(n+m)
obj     = [0.0]

kp = createProblem()
setOption(kp, "hessopt", 6)
initializeProblem(kp, objGoal, objType, x_L, x_U, c_Type, c_L, c_U, jac_var, jac_con)
setFuncCallback(kp, eval_f, eval_g)
setGradCallback(kp, eval_grad_f, eval_jac_g)
solveProblem(kp)

# --- test optimal solutions ---
@testset "Test optimal solution" begin
    @test applicationReturnStatus(kp) == :Optimal
    @test isapprox(kp.x, [1.3333333, 0.7777777, 0.4444444], atol=1e-5)
    @test isapprox(kp.obj_val[1], 0.1111111, atol=1e-5)
end

freeProblem(kp)
