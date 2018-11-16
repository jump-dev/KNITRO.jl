# Knitro model attributes

##################################################
# Low level attribute getters/setters
##################################################



##################################################
# objective
#
function KN_set_obj_goal(m::Model, objgoal::Cint)
    return_code = @kn_ccall(set_obj_goal, Cint, (Ptr{Nothing}, Cint),
                             m.env.ptr_env.x, objgoal)
    if return_code != 0
        error("KNITRO: Fail to reset default params")
    end
end

function KN_add_obj_linear_struct(m::Model,
                                  objIndices::Vector{Cint},
                                  objCoefs::Vector{Cdouble})
    nnz = length(objIndices)

    return_code = @kn_ccall(add_obj_linear_struct, Cint,
                            (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                            m.env.ptr_env.x,
                            nnz,
                            objIndices,
                            objCoefs)
    if return_code != 0
        error("KNITRO: Fail to reset default params")
    end
end


