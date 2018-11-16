

function KN_get_number_FC_evals(m::Model)
    fc_eval = Int32[0]
    ret = @kn_ccall(get_number_FC_evals, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, fc_eval)
    _checkraise(ret)
    return fc_eval[1]
end

function KN_get_number_GA_evals(m::Model)
    fc_eval = Int32[0]
    ret = @kn_ccall(get_number_GA_evals, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, fc_eval)
    _checkraise(ret)
    return fc_eval[1]
end

function KN_get_number_H_evals(m::Model)
    fc_eval = Int32[0]
    ret = @kn_ccall(get_number_H_evals, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, fc_eval)
    _checkraise(ret)
    return fc_eval[1]
end

function KN_get_number_HV_evals(m::Model)
    fc_eval = Int32[0]
    ret = @kn_ccall(get_number_HV_evals, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, fc_eval)
    _checkraise(ret)
    return fc_eval[1]
end
