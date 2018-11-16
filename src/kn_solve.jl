# Optimization and solution query

function KN_solve(m::Model)
    ret = @kn_ccall(solve, Cint, (Ptr{Nothing},), m.env.ptr_env.x)
    # For KN_solve, we do not return an error if ret is different of 0
    return ret
end


##################################################
# Solution status and info
##################################################
# TODO
function KN_get_solution(m::Model)
    status = 0
    obj = 0.
    nx = KN_get_
    nc =
    x = zeros(Cdouble, nx)
    lambda = zeros(Cdouble, nc)
    ret = @kn_ccall(get_solution, Cint,
                    (Ptr{Nothing},),
                    m.env.ptr_env.x)

    return status, obj, x, lambda
end
