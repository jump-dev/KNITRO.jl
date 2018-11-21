# Knitro model


##################################################
# Model definition
##################################################
mutable struct Model
    env::Env
    eval_status::Int32 # scalar input used only for reverse comms
    status::Int32  # Final status
    mip::Bool # whether it is a Mixed Integer Problem
    userdata::Dict

    eval_f::Function
    eval_g::Function
    eval_grad_f::Function
    eval_jac_g::Function
    eval_h::Function
    eval_rsd::Function
    eval_rsdj::Function
    eval_mip_node::Function
    user_callback::Function


    function Model(env::Env)
        model = new(env, Int32(0), Int32(100), false, Dict())

        res = @kn_ccall(new, Cint, (Ptr{Nothing},), env.ptr_env)
        if res != 0
            error("KNITRO: Error creating solver")
        end
        finalizer(KN_free, model)
        return model
    end
end


KN_free(m::Model) = free_env(m.env)

KN_new() = Model(Env())


##################################################
# Model manipulation
##################################################

# parameters
"Set all parameters specified in the given file"
function KN_load_param_file(m::Model, filename::AbstractString)
    ret = @kn_ccall(load_param_file, Cint, (Ptr{Nothing}, Ptr{Cchar}),
                             m.env.ptr_env.x, filename)
    _checkraise(ret)
end

"Reset all parameters to default values"
function KN_reset_params_to_defaults(m::Model)
    ret = @kn_ccall(reset_params_to_defaults, Cint, (Ptr{Nothing}, ),
                             m.env.ptr_env.x)
    _checkraise(ret)
end

"Set tuner file."
function KN_load_tuner_file(m::Model, filename::AbstractString)
    ret = @kn_ccall(load_tuner_file, Cint, (Ptr{Nothing}, Ptr{Cchar}),
                             m.env.ptr_env.x, filename)
    _checkraise(ret)
end
