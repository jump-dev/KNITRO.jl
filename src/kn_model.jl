# Knitro model


##################################################
# Model definition
##################################################
mutable struct Model
    # KNITRO context environment
    env::Env
    eval_status::Int32 # scalar input used only for reverse comms
    status::Int32  # Final status
    userdata::Dict

    # special callbacks (undefined by default)
    # (this functions do not depend on callback environments)
    ms_process::Function
    mip_callback::Function
    user_callback::Function
    ms_initpt_callback::Function
    puts_callback::Function

    # constructor
    function Model(env::Env)
        model = new(env, Int32(0), Int32(-1), Dict())

        res = @kn_ccall(new, Cint, (Ptr{Nothing},), env.ptr_env)
        if res != 0
            error("KNITRO: Error creating solver")
        end
        # add a destructor to properly delete model
        finalizer(KN_free, model)
        return model
    end
end

# free the environment
KN_free(m::Model) = free_env(m.env)

KN_new() = Model(Env())


##################################################
# Basic model manipulation
##################################################

"Set all parameters specified in the given file"
function KN_load_param_file(m::Model, filename::AbstractString)
    ret = @kn_ccall(load_param_file, Cint, (Ptr{Nothing}, Ptr{Cchar}),
                    m.env.ptr_env.x, filename)
    _checkraise(ret)
end

"Save current parameters in the given file"
function KN_save_param_file(m::Model, filename::AbstractString)
    ret = @kn_ccall(save_param_file, Cint, (Ptr{Nothing}, Ptr{Cchar}),
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
