# Knitro model


##################################################
# Model definition
##################################################
mutable struct Model
    env::Env
    eval_status::Int32 # scalar input used only for reverse comms
    status::Int32  # Final status
    mip::Bool # whether it is a Mixed Integer Problem

    function Model(env::Env)
        model = new(env, Int32(0), Int32(100), false)

        res = @kn_ccall(new, Cint, (Ptr{Nothing},), env.ptr_env)
        if res != 0
            error("KNITRO: Error creating solver")
        end
        finalizer(finalize_model, model)
        return model
    end
end


function finalize_model(m::Model)
    free_env(m.env)
end


##################################################
# Model manipulation
##################################################

# parameters
"Set all parameters specified in the given file"
function KN_load_param_file(m::Model, filename::AbstractString)
    return_code = @kn_ccall(load_param_file, Cint, (Ptr{Nothing}, Ptr{Cchar}),
                             m.env.ptr_env.x, filename)
    if return_code != 0
        error("KNITRO: Error loading parameters from $(filename)")
    end
end

"Reset all parameters to default values"
function KN_reset_params_to_defaults(m::Model)
    return_code = @kn_ccall(reset_params_to_defaults, Cint, (Ptr{Nothing}, ),
                             m.env.ptr_env.x)
    if return_code != 0
        error("KNITRO: Fail to reset default params")
    end
end

