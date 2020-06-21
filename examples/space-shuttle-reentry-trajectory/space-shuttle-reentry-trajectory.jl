#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# This example demonstrates how to use Knitro to calculate a reentry
# trajectory for the space shuttle, which is a large and sparse
# nonlinear trajectory optimization problem.
#
# This example shows how to integrate multiple functionalities:
# - Definition of separate callbacks for constraint function
#   evaluation and constraint Jacobian evaluation;
# - Automatic detection of the Jacobian sparsity pattern;
# - Automatic differentiation for Jacobian evaluation;
# - Definition of lower and upper bounds for decision variables;
# - Setting an initial seed (for the primal values) based on a
#   linear interpolation to improve convergence speed;
# - Setup of an objective function with a linear structure;
# - Manual specification of solver user-options.
#
# This model is directly based on the optimal control example from
# chapter 6.1 in the book "Practical Methods for Optimal Control and
# Estimation Using Nonlinear Programming" by John T. Betts (2010).
#
# A companion video with a brief explanation of the formulation is
# available at https://youtu.be/fBY_yHkyU3A.
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

using Interpolations
using KNITRO
using SparseArrays
using SparseDiffTools
using SparsityDetection

# Global variables
const w  = 203000  # weight (lb)
const g₀ = 32.174  # acceleration (ft/sec^2)
const m  = w / g₀  # mass (slug)

# Aerodynamic and atmospheric forces on the vehicle
const ρ₀ =  0.002378
const hᵣ =  23800.0
const Rₑ =  20902900.0
const μ  =  0.14076539e17
const S  =  2690.0
const a₀ = -0.20704
const a₁ =  0.029244
const b₀ =  0.07854
const b₁ = -0.61592e-2
const b₂ =  0.621408e-3
const c₀ =  1.0672181
const c₁ = -0.19213774e-1
const c₂ =  0.21286289e-3
const c₃ = -0.10117249e-5

c_L(a) = a₀ + a₁ * rad2deg(a)
c_D(a) = b₀ + b₁ * rad2deg(a) + b₂ * rad2deg(a)^2

D(h, v, a) = 0.5 * c_D(a) * S * ρ(h) * v^2
L(h, v, a) = 0.5 * c_L(a) * S * ρ(h) * v^2

r(h) = Rₑ + h
g(h) = μ / r(h)^2
ρ(h) = ρ₀ * exp(-h / hᵣ)

# Aerodynamic heating on the vehicle wing leading edge
qₐ(a) = c₀ + c₁ * rad2deg(a) + c₂ * rad2deg(a)^2 + c₃ * rad2deg(a)^3
qᵣ(h, v) = 17700 * √ρ(h) * (0.0001 * v)^3.07
q(h, v, a) = qₐ(a) * qᵣ(h, v)

# Motion of the vehicle as a differential-algebraic system of equations (DAEs)
δh(v, γ) = v * sin(γ)
δϕ(h, θ, v, γ, ψ) = (v / r(h)) * cos(γ) * sin(ψ) / cos(θ)
δθ(h, v, γ, ψ) = (v / r(h)) * cos(γ) * cos(ψ)
δv(h, v, γ, α) = -(D(h, v, α) / m) - g(h) * sin(γ)
δγ(h, v, γ, α, β) = (L(h, v, α) / (m * v)) * cos(β) + cos(γ) * ((v / r(h)) - (g(h) / v))
δψ(h, θ, v, γ, ψ, α, β) = (1 / (m * v * cos(γ))) * L(h, v, α) * sin(β) + (v / (r(h) * cos(θ))) * cos(γ) * sin(ψ) * sin(θ)

# Initial conditions
hₛ = 2.6          # altitude (ft) / 1e5
ϕₛ = deg2rad(0)   # longitude (rad)
θₛ = deg2rad(0)   # latitude (rad)
vₛ = 2.56         # velocity (ft/sec) / 1e4
γₛ = deg2rad(-1)  # flight path angle (rad)
ψₛ = deg2rad(90)  # azimuth (rad)
αₛ = deg2rad(0)   # angle of attack (rad)
βₛ = deg2rad(0)   # banck angle (rad)
tₛ = 1.00         # time step (sec)

# Final conditions, the so-called Terminal Area Energy Management (TAEM)
hₜ = 0.8          # altitude (ft) / 1e5
vₜ = 0.25         # velocity (ft/sec) / 1e4
γₜ = deg2rad(-5)  # flight path angle (rad)

xₛ = [hₛ, ϕₛ, θₛ, vₛ, γₛ, ψₛ, αₛ, βₛ, tₛ]
xₜ = [hₜ, ϕₛ, θₛ, vₜ, γₜ, ψₛ, αₛ, βₛ, tₛ]

@show xₛ xₜ;

N = 2008  # number of segments
M = N + 1  # number of mesh points

# Linear initial guess between the boundary conditions
interp_linear = LinearInterpolation([1, M], [xₛ, xₜ])
seed = [value for x = 1:M for value in interp_linear(x)]

nₓ = length(xₛ)  # mesh points dimension
n = nₓ * M  # number of decision variables
@assert n == length(seed)

ind_h = 1:nₓ:n  # indices of the `h` decision variables
ind_ϕ = 2:nₓ:n  # indices of the `ϕ` decision variables
ind_θ = 3:nₓ:n  # indices of the `θ` decision variables
ind_v = 4:nₓ:n  # indices of the `v` decision variables
ind_γ = 5:nₓ:n  # indices of the `γ` decision variables
ind_ψ = 6:nₓ:n  # indices of the `ψ` decision variables
ind_α = 7:nₓ:n  # indices of the `α` decision variables
ind_β = 8:nₓ:n  # indices of the `β` decision variables
ind_t = 9:nₓ:n  # indices of the `t` decision variables
@assert length(ind_h) == length(ind_v) == length(ind_α) == M

m_dyn = 6 * N
ind_con_dyn = 1:m_dyn  # indices of the dynamics' constraints (defects)
@assert length(ind_con_dyn) == 6 * (M - 1)

EulerStep(x, δx, h) = x + h*δx

function dynamics_defects!(dx, x)
    hᵢ, ϕᵢ, θᵢ, vᵢ, γᵢ, ψᵢ, αᵢ, βᵢ, tᵢ, hⱼ, ϕⱼ, θⱼ, vⱼ, γⱼ, ψⱼ = x

    # Unit correction due to decision variable scaling
    hᵢ *= 1e5; hⱼ *= 1e5; vᵢ *= 1e4; vⱼ *= 1e4

    dx[1] = EulerStep(hᵢ, δh(        vᵢ, γᵢ            ), tᵢ) - hⱼ
    dx[2] = EulerStep(ϕᵢ, δϕ(hᵢ, θᵢ, vᵢ, γᵢ, ψᵢ        ), tᵢ) - ϕⱼ
    dx[3] = EulerStep(θᵢ, δθ(hᵢ,     vᵢ, γᵢ, ψᵢ        ), tᵢ) - θⱼ
    dx[4] = EulerStep(vᵢ, δv(hᵢ,     vᵢ, γᵢ,     αᵢ    ), tᵢ) - vⱼ
    dx[5] = EulerStep(γᵢ, δγ(hᵢ,     vᵢ, γᵢ,     αᵢ, βᵢ), tᵢ) - γⱼ
    dx[6] = EulerStep(ψᵢ, δψ(hᵢ, θᵢ, vᵢ, γᵢ, ψᵢ, αᵢ, βᵢ), tᵢ) - ψⱼ

    return nothing
end

function cb_eval_fc_con_dyn(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x

    for i = 0:M - 2
        ind_xᵢ = (1:nₓ) .+ i * nₓ
        ind_xⱼ = ind_xᵢ .+ nₓ
        ind_con = (1:6) .+ i * 6

        xᵢ = x[ind_xᵢ][1:9]
        xⱼ = x[ind_xⱼ][1:6]

        @views dynamics_defects!(evalResult.c[ind_con], [xᵢ; xⱼ])
    end

    return 0
end

function cb_eval_ga_con_dyn(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x
    jac_data = userParams

    for i = 0:M - 2
        ind_xᵢ = (1:nₓ) .+ i * nₓ
        ind_xⱼ = ind_xᵢ .+ nₓ
        ind_con = (1:6) .+ i * 6

        xᵢ = x[ind_xᵢ][1:9]
        xⱼ = x[ind_xⱼ][1:6]

        forwarddiff_color_jacobian!(jac_data.jac_dyn, dynamics_defects!, [xᵢ; xⱼ], jac_data.jac_cache)

        aux_jac = i * jac_data.length_jac
        ind_jac = aux_jac + 1 : aux_jac + jac_data.length_jac
        evalResult.jac[ind_jac] = nonzeros(jac_data.jac_dyn)
    end

    return 0
end

struct JacobianData
    jac_dyn
    jac_cache
    length_jac

    function JacobianData(;
                          input = rand(15), output = zeros(6))
        sparsity_pattern = jacobian_sparsity(dynamics_defects!, output, input)
        jac_dyn = convert.(Float64, sparse(sparsity_pattern))
        
        jac_cache = ForwardColorJacCache(dynamics_defects!, input, dx = output,
                                         colorvec = matrix_colors(jac_dyn),
                                         sparsity = sparsity_pattern)

        length_jac = nnz(jac_dyn)

        new(jac_dyn, jac_cache, length_jac)
    end
end

input = rand(15)
jac_data = JacobianData(input = input)
forwarddiff_color_jacobian!(jac_data.jac_dyn, dynamics_defects!, input, jac_data.jac_cache)

jacIndexConsCB = Cint.(hcat([rowvals(jac_data.jac_dyn) .+ i*6 for i = 0:N-1]...) .- 1)
jacIndexVarsCB = Cint.(hcat([vcat([fill(j + i*nₓ, length(nzrange(jac_data.jac_dyn, j))) for j = 1:15]...) for i = 0:N-1]...) .- 1)

# Note: the code above this point formulates the problem, and implements
# callbacks in a format compatible with Knitro's interface, but the
# actual use of Knitro only starts from this point onwards.

lm = KNITRO.LMcontext()
kc = KNITRO.KN_new_lm(lm)

KNITRO.KN_add_vars(kc, n)

!isempty(seed) && KNITRO.KN_set_var_primal_init_values(kc, seed)

KNITRO.KN_set_var_lobnds(kc, collect(Cint, ind_h .- 1), zeros(M))  # `h` bounds
KNITRO.KN_set_var_lobnds(kc, collect(Cint, ind_v .- 1), fill(1 / 1e4, M))  # `v` bounds

KNITRO.KN_set_var_lobnds(kc, collect(Cint, ind_θ .- 1), fill(deg2rad(-89), M))  # `θ` lower bounds
KNITRO.KN_set_var_upbnds(kc, collect(Cint, ind_θ .- 1), fill(deg2rad( 89), M))  # `θ` upper bounds

KNITRO.KN_set_var_lobnds(kc, collect(Cint, ind_γ .- 1), fill(deg2rad(-89), M))  # `γ` lower bounds
KNITRO.KN_set_var_upbnds(kc, collect(Cint, ind_γ .- 1), fill(deg2rad( 89), M))  # `γ` upper bounds

KNITRO.KN_set_var_lobnds(kc, collect(Cint, ind_α .- 1), fill(deg2rad(-90), M))  # `α` lower bounds
KNITRO.KN_set_var_upbnds(kc, collect(Cint, ind_α .- 1), fill(deg2rad( 90), M))  # `α` upper bounds

KNITRO.KN_set_var_lobnds(kc, collect(Cint, ind_β .- 1), fill(deg2rad(-89), M))  # `β` lower bounds
KNITRO.KN_set_var_upbnds(kc, collect(Cint, ind_β .- 1), fill(deg2rad(  1), M))  # `β` upper bounds

KNITRO.KN_set_var_fxbnds(kc, collect(Cint, ind_t .- 1), fill(1.00, M))  # Fix time steps

# Fix initial and final conditions
ind_fixed_vars = [ind_h[1]:ind_ψ[1] ; [ind_h[end], ind_v[end], ind_γ[end]]]
val_fixed_vars = [hₛ, ϕₛ, θₛ, vₛ, γₛ, ψₛ, hₜ, vₜ, γₜ]
KNITRO.KN_set_var_fxbnds(kc, collect(Cint, ind_fixed_vars .- 1), val_fixed_vars)

KNITRO.KN_add_cons(kc, m_dyn)

KNITRO.KN_set_con_eqbnds(kc, collect(Cint, ind_con_dyn .- 1), zeros(m_dyn))  # defects

# This callback does not evaluate the objective function. As such,
# we pass `false` as the second argument to `KN_add_eval_callback()`.
cb_dyn = KNITRO.KN_add_eval_callback(kc, false, collect(Cint, ind_con_dyn .- 1), cb_eval_fc_con_dyn)

# Similarly to above, this callback does not evaluate the gradient of the objective.
# As such, we pass `nV = 0`, and `objGradIndexVars = C_NULL` in the `KN_set_cb_grad()` call.
KNITRO.KN_set_cb_grad(kc, cb_dyn, cb_eval_ga_con_dyn,
                      nV = 0, objGradIndexVars = C_NULL,
                      jacIndexCons = jacIndexConsCB,
                      jacIndexVars = jacIndexVarsCB)

KNITRO.KN_set_cb_user_params(kc, cb_dyn, jac_data)

# Add objective
objIndex, objCoef = ind_θ[end], 1.0
KNITRO.KN_add_obj_linear_struct(kc, objIndex - 1, objCoef)
KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MAXIMIZE)

KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_ALG,        KNITRO.KN_ALG_BAR_DIRECT)
KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_BAR_MURULE, KNITRO.KN_BAR_MURULE_PROBING)
KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_LINSOLVER,  KNITRO.KN_LINSOLVER_MA27)
KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_MAXTIMECPU, 20.0)  # Default: 1.0e8

KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_HESSOPT, KNITRO.KN_HESSOPT_LBFGS)
KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_LMSIZE, 5)  # limited-memory pairs stored

KNITRO.KN_solve(kc)
nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
cpu_time = KNITRO.KN_get_solve_time_real(kc)

KNITRO.KN_free(kc)
KNITRO.KN_release_license(lm)

print("Final latitude θ = $(round(rad2deg(x[ind_θ[end]]), digits = 2))°")
