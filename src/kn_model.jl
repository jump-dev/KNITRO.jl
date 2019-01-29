# Knitro model


##################################################
# Model definition
##################################################
mutable struct Model
    # KNITRO context environment
    env::Env
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
        model = new(env, Dict())

        res = @kn_ccall(new, Cint, (Ptr{Nothing},), env.ptr_env)
        if res != 0
            error("KNITRO: Error creating solver")
        end
        # add a destructor to properly delete model
        finalizer(KN_free, model)
        return model
    end
    # create Model with license manager
    function Model(env::Env, lm::LMcontext)
        model = new(env, Dict())
        res = @kn_ccall(new_lm, Cint, (Ptr{Nothing}, Ptr{Nothing}),
                    lm.ptr_lmcontext.x, env.ptr_env)

        model = Model(env)
        @assert res == 0

        finalizer(KN_free, model)
        return model
    end
end

"Free solver object."
KN_free(m::Model) = free_env(m.env)

"Create solver object."
KN_new() = Model(Env())
KN_new_lm(lm::LMcontext) = Model(Env(), lm)

is_valid(m::Model) = is_valid(m.env)



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

function KN_load_mps_file(m::Model, filename::AbstractString)
    ret = @kn_ccall(load_mps_file, Cint, (Ptr{Nothing}, Ptr{Cchar}),
                    m.env.ptr_env.x, filename)
    _checkraise(ret)
end
