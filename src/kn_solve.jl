# Optimization and solution query

function KN_solve(m::Model)
    ret = @kn_ccall(solve, Cint, (Ptr{Nothing},), m.env.ptr_env.x)
    # For KN_solve, we do not return an error if ret is different of 0
    return ret
end

##################################################
# Solution status and info
##################################################
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
                    (Ptr{Nothing}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
                    m.env.ptr_env.x, status, obj, x, lambda)

    return status[1], obj[1], x, lambda
end

# some wrapper functions for MOI
get_status(m::Model) = KN_get_solution(m)[1]
get_objective(m::Model) = KN_get_solution(m)[2]
get_solution(m::Model) = KN_get_solution(m)[3]
get_dual(m::Model) = KN_get_solution(m)[4]
