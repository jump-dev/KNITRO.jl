# Variables utilities


function KN_add_var!(m::Model)

    ptr_int = [0]
    ret = @kn_ccall(add_var, Cint, (Ptr{Nothing}, Ptr{Cint}), m.env.ptr_env.x, ptr_int)

    if ret != 0
        # TODO: improve gestion of errors
        error("Fail to load variable in model: $ret")
    end
    return ptr_int[1]
end


function KN_add_vars!(m::Model, nvars::Int)

    ptr_int = zeros(Cint, nvars)
    ret = @kn_ccall(add_vars, Cint, (Ptr{Nothing}, Cint, Ptr{Cint}), m.env.ptr_env.x, nvars, ptr_int)

    if ret != 0
        # TODO: improve gestion of errors
        error("Fail to load variable in model: $ret")
    end
    return ptr_int
end


function KN_set_var_lobnd(m::Model, nindex::Cint, val::Cdouble)
    ret = @kn_ccall(set_var_lobnd, Cint, (Ptr{Nothing}, Cint, Cdouble), m.env.ptr_env.x, nindex, val)
    if ret != 0
        # TODO: improve gestion of errors
        error("Fail to load variable in model: $ret")
    end
end

function KN_set_var_upbnd(m::Model, nindex::Cint, val::Cdouble)
    ret = @kn_ccall(set_var_upbnd, Cint, (Ptr{Nothing}, Cint, Cdouble), m.env.ptr_env.x, nindex, val)
    if ret != 0
        # TODO: improve gestion of errors
        error("Fail to load variable in model: $ret")
    end
end
