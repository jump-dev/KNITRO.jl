# Optimization and solution query

function KN_solve(m::Model)
    ret = @kn_ccall(solve, Cint, (Ptr{Nothing},), m.env.ptr_env.x)
    m.status = ret
    # For KN_solve, we do not return an error if ret is different of 0
    return ret
end

##################################################
# Solution status and info
##################################################
function KN_get_solution(m::Model)
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
