# Knitro model.


##################################################
# Model definition.
##################################################
mutable struct Model
    # KNITRO context environment.
    env::Env
    userdata::Dict

    # Solution values.
    # Optimization status. Equal to 1 if problem is unsolved.
    status::Cint
    obj_val::Cdouble
    x::Vector{Cdouble}
    mult::Vector{Cdouble}

    # Special callbacks (undefined by default).
    # (this functions do not depend on callback environments)
    ms_process::Function
    mip_callback::Function
    user_callback::Function
    ms_initpt_callback::Function
    puts_callback::Function

    # Constructor.
    function Model()
        model = new(Env(), Dict(), 1, Inf, Cdouble[], Cdouble[])
        # Add a destructor to properly delete model.
        finalizer(KN_free, model)
        return model
    end
    Model(env::Env, options::Dict) = new(env, options)
end

"Free solver object."
KN_free(m::Model) = free_env(m.env)

"Create solver object."
KN_new() = Model()

is_valid(m::Model) = is_valid(m.env)


##################################################
# Basic model manipulation
##################################################

"Set all parameters specified in the given file."
function KN_load_param_file(m::Model, filename::AbstractString)
    ret = @kn_ccall(load_param_file, Cint, (Ptr{Cvoid}, Ptr{Cchar}),
                    m.env, filename)
    _checkraise(ret)
end

"Save current parameters in the given file."
function KN_save_param_file(m::Model, filename::AbstractString)
    ret = @kn_ccall(save_param_file, Cint, (Ptr{Cvoid}, Ptr{Cchar}),
                    m.env, filename)
    _checkraise(ret)
end

"Reset all parameters to default values."
function KN_reset_params_to_defaults(m::Model)
    ret = @kn_ccall(reset_params_to_defaults, Cint, (Ptr{Cvoid}, ),
                    m.env)
    _checkraise(ret)
end

"Set tuner file."
function KN_load_tuner_file(m::Model, filename::AbstractString)
    ret = @kn_ccall(load_tuner_file, Cint, (Ptr{Cvoid}, Ptr{Cchar}),
                    m.env, filename)
    _checkraise(ret)
end

"Load MPS file."
function KN_load_mps_file(m::Model, filename::AbstractString)
    @assert KNITRO_VERSION >= v"12.0"
    ret = @kn_ccall(load_mps_file, Cint, (Ptr{Cvoid}, Ptr{Cchar}),
                    m.env, filename)
    _checkraise(ret)
end


##################################################
# LM license manager
##################################################
"""
Type declaration for the Artelys License Manager context object.
Applications must not modify any part of the context.
"""
mutable struct LMcontext
    ptr_lmcontext::Ptr{Cvoid}
    # Keep a pointer to instantiated models in order to free
    # memory properly.
    linked_models::Vector{Model}

    function LMcontext()
        ptrref = Ref{Ptr{Cvoid}}()
        res = @kn_ccall(checkout_license, Cint, (Ptr{Cvoid},), ptrref)
        if res != 0
            error("KNITRO: Error checkout license")
        end
        lm = new(ptrref[], Model[])
        finalizer(KN_release_license, lm)
        return lm
    end
end

function Env(lm::LMcontext)
    ptrptr_env = Ref{Ptr{Cvoid}}()
    res = @kn_ccall(new_lm, Cint, (Ptr{Cvoid},Ptr{Cvoid}), lm.ptr_lmcontext, ptrptr_env)
    if res != 0
        error("Fail to retrieve a valid KNITRO KN_context. Error $res")
    end
    Env(ptrptr_env[])
end

function attach!(lm::LMcontext, model::Model)
    push!(lm.linked_models, model)
    return
end

# create Model with license manager
function Model(lm::LMcontext)
    model = Model(Env(lm), Dict())
    attach!(lm, model)
    return model
end
KN_new_lm(lm::LMcontext) = Model(lm)

function KN_release_license(lm::LMcontext)
    # First, ensure that all linked models are properly freed
    # before releasing license manager!
    KN_free.(lm.linked_models)

    if lm.ptr_lmcontext != C_NULL
        refptr = Ref{Ptr{Cvoid}}(lm.ptr_lmcontext)
        @kn_ccall(release_license, Cint, (Ptr{Cvoid},), refptr)
        lm.ptr_lmcontext = C_NULL
    end
end
