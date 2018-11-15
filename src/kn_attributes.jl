# Knitro model attributes

##################################################
# Low level attribute getters/setters
##################################################



##################################################
# objective
#
function KN_set_obj_goal(m::Model, objgoal::Int)
    return_code = @kn_ccall(set_obj_goal, Cint, (Ptr{Nothing}, Cint),
                             m.env.ptr_env.x, objgoal)
    if return_code != 0
        error("KNITRO: Fail to reset default params")
    end
end
