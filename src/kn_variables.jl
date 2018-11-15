# Variables utilities



function KN_add_var!(m::Model)

    ret = @kn_call(add_var, Cint, (Ptr{Nothing}, Cint), m.env.ptr_env.x, 0)

    if ret != 0
        # TODO: improve gestion of errors
        error("Fail to load variable in model: $ret")
    end
end


function KN_add_vars!(m::Model, nvars::Int)

    ret = @kn_call(add_vars, Cint, (Ptr{Nothing}, Cint), m.env.ptr_env.x, nvars)

    if ret != 0
        # TODO: improve gestion of errors
        error("Fail to load variable in model: $ret")
    end
end

