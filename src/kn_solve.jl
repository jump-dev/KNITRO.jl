# Optimization and solution query

"""
Call Knitro to solve the problem.  The return value indicates
the solution status.

"""
function KN_solve(m::Model)
    ret = @kn_ccall(solve, Cint, (Ptr{Cvoid},), m.env)
    # For KN_solve, we do not return an error if ret is different of 0
    return ret
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

    return status[1], obj[1], x, lambda
end

# some wrapper functions for MOI
function get_status(m::Model)
    @assert m.env != C_NULL
    status = Cint[0]
    obj = Cdouble[0.]
    ret = @kn_ccall(get_solution, Cint,
                    (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
                    m.env, status, obj, C_NULL, C_NULL)
    return status[1]
end

function get_objective(m::Model)
    @assert m.env != C_NULL
    status = Cint[0]
    obj = Cdouble[0.]
    ret = @kn_ccall(get_solution, Cint,
                    (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
                    m.env, status, obj, C_NULL, C_NULL)
    return obj[1]
end

function get_solution(m::Model)
    # we first check that the model is well defined to avoid segfault
    @assert m.env != C_NULL
    nx = KN_get_number_vars(m)
    x = zeros(Cdouble, nx)
    status = Cint[0]
    obj = Cdouble[0.]
    ret = @kn_ccall(get_solution, Cint,
                    (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
                    m.env, status, obj, x, C_NULL)
    return x
end

function get_dual(m::Model)
    # we first check that the model is well defined to avoid segfault
    @assert m.env != C_NULL
    nx = KN_get_number_vars(m)
    nc = KN_get_number_cons(m)
    lambda = zeros(Cdouble, nx + nc)
    status = Cint[0]
    obj = Cdouble[0.]
    ret = @kn_ccall(get_solution, Cint,
                    (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
                    m.env, status, obj, C_NULL, lambda)
    return lambda
end
