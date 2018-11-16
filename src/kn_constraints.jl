# Constraints utilities


function KN_add_cons!(m::Model, ncons::Int)
    ptr_cons = zeros(Cint, ncons)
    ret = @kn_ccall(add_cons, Cint, (Ptr{Nothing}, Cint, Ptr{Cint}), m.env.ptr_env.x, ncons, ptr_cons)
    if ret != 0
        error("Fail to load variable in model: $ret")
    end
    return ptr_cons
end


function KN_add_con!(m::Model)
    ptr_cons = [0]
    ret = @kn_ccall(add_con, Cint, (Ptr{Nothing}, Ptr{Cint}), m.env.ptr_env.x, ptr_cons)

    if ret != 0
        error("Fail to load variable in model: $ret")
    end
    return ptr_cons
end

function KN_set_con_eqbnds(m::Model, indexCons::Vector{Cint})
    error("To implement")
end

function KN_set_con_eqbnds!(m::Model, eqBnds::Vector{Cdouble})
    ret = @kn_ccall(set_con_eqbnds_all, Cint, (Ptr{Nothing}, Ptr{Cdouble}), m.env.ptr_env.x, eqBnds)
    if ret != 0
        error("Fail to load variable in model: $ret")
    end
end


function KN_add_con_linear_struct(m::Model,
                                  jacIndexCons::Vector{Int},
                                  jacIndexVars::Vector{Int},
                                  jacCoefs::Vector{Float64})
    # get number of constraints
    nnz = length(jacIndexCons)
    ret = @kn_ccall(add_con_linear_struct,
                    Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x,
                    nnz,
                    jacIndexCons,
                    jacIndexVars,
                    jacCoefs)
    if ret != 0
        error("Fail to load variable in model: $ret")
    end
end
