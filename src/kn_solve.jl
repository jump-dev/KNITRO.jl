# Optimization and solution query.

"""
Call Knitro to solve the problem. The return value indicates
the solution status.

"""
function KN_solve(m::Model)
    # Check sanity. If model has Julia callbacks, we need to ensure
    # that Knitro is not multithreaded. Otherwise, the code will segfault
    # as we have trouble calling Julia code from multithreaded C
    # code. See issue #93 on https://github.com/jump-dev/KNITRO.jl.
    if has_callbacks(m)
        KN_set_param(m, "par_numthreads", 1)
        KN_set_param(m, "par_msnumthreads", 1)
    end
    # For KN_solve, we do not return an error if ret is different of 0.
    m.status = @kn_ccall(solve, Cint, (Ptr{Cvoid},), m.env)
    return m.status
end

##################################################
# Solution status and info
##################################################
"Return the solution status, objective, primal and dual variables."
function KN_get_solution(m::Model)
    # we first check that the model is well defined to avoid segfault
    @assert m.env != C_NULL
    nx = KN_get_number_vars(m)
    nc = KN_get_number_cons(m)

    x = zeros(Cdouble, nx)
    lambda = zeros(Cdouble, nx + nc)
    status = Cint[0]
    obj = Cdouble[0.]

    ret = @kn_ccall(get_solution, Cint,
                    (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
                    m.env, status, obj, x, lambda)

    # Keep solution in cache.
    m.status = status[1]
    m.x = x
    m.mult = lambda
    m.obj_val = obj[1]
    return status[1], obj[1], x, lambda
end

# some wrapper functions for MOI
function get_status(m::Model)
    @assert m.env != C_NULL
    if m.status != 1
        return m.status
    end
    status = Cint[0]
    obj = Cdouble[0.]
    ret = @kn_ccall(get_solution, Cint,
                    (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
                    m.env, status, obj, C_NULL, C_NULL)
    # Keep status in cache.
    m.status = status[1]
    return status[1]
end

function get_objective(m::Model)
    @assert m.env != C_NULL
    if isfinite(m.obj_val)
        return m.obj_val
    end
    status = Cint[0]
    obj = Cdouble[0.]
    ret = @kn_ccall(get_solution, Cint,
                    (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
                    m.env, status, obj, C_NULL, C_NULL)
    # Keep objective value in cache.
    m.obj_val = obj[1]
    return obj[1]
end

function get_solution(m::Model)
    # We first check that the model is well defined to avoid segfault.
    @assert m.env != C_NULL
    if !isempty(m.x)
        return m.x
    end
    nx = KN_get_number_vars(m)
    x = zeros(Cdouble, nx)
    status = Cint[0]
    obj = Cdouble[0.]
    ret = @kn_ccall(get_solution, Cint,
                    (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
                    m.env, status, obj, x, C_NULL)
    # Keep solution in cache.
    m.x = x
    return x
end
get_solution(m::Model, ix::Int) = isempty(m.x) ? get_solution(m)[ix] : m.x[ix]

function get_dual(m::Model)
    # we first check that the model is well defined to avoid segfault
    @assert m.env != C_NULL
    if !isempty(m.mult)
        return m.mult
    end
    nx = KN_get_number_vars(m)
    nc = KN_get_number_cons(m)
    lambda = zeros(Cdouble, nx + nc)
    status = Cint[0]
    obj = Cdouble[0.]
    ret = @kn_ccall(get_solution, Cint,
                    (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
                    m.env, status, obj, C_NULL, lambda)
    # Keep multipliers in cache.
    m.mult = lambda
    return lambda
end
get_dual(m::Model, ix::Int) = isempty(m.mult) ? get_dual(m)[ix] : m.mult[ix]


# New getters for Knitro >= 12.0
if KNITRO_VERSION >= v"12.0"
    @define_getters get_var_primal_values
    @define_getters get_var_dual_values
    @define_getters get_con_dual_values
end

if KNITRO_VERSION >= v"12.4"
    function KN_get_presolve_error(m::Model)
        @assert m.env != C_NULL
        component, index, error = Cint[0], Cint[0], Cint[0]
        viol = Cdouble[0.0]
        ret = @kn_ccall(get_presolve_error, Cint,
                        (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                        m.env, component, index, error, viol)
        _checkraise(ret)
        return convert(Bool, component[1]), convert(Int64, index[1]), convert(Int64, error[1]) , convert(Float64, viol[1]) 
    end
end