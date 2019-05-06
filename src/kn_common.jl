# Common functions


# KNITRO special types
const KNLONG = Clonglong
const KNBOOL = Cint


"A macro to make calling KNITRO's KN_* C API a little cleaner"
macro kn_ccall(func, args...)
    f = Base.Meta.quot(Symbol("KN_$(func)"))
    args = [esc(a) for a in args]
    quote
        ccall(($f, libknitro), $(args...))
    end
end

macro define_getters(function_name)
    fname = Symbol("KN_" * string(function_name))
    quote
        function $(esc(fname))(kc::Model, index::Vector{Cint})
            result = zeros(Cdouble, length(index))
            ret = @kn_ccall($function_name, Cint,
                            (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                            kc.env, length(index), index, result)
            _checkraise(ret)
            return result
        end
    end
end

"Check if return value is valid."
function _checkraise(ret::Cint)
    if ret != 0
        error("Fail to use specified function: $ret")
    end
end

"Format output returned by KNITRO as proper Julia string."
function format_output(output::AbstractString)
    # remove trailing whitespace
    res = strip(output)
    # remove special characters
    res = strip(res, '\0')
end

"Return the current KNITRO version."
function get_release()
    len = 15
    out = zeros(Cchar,len)

    @kn_ccall(get_release, Cvoid, (Cint, Ptr{Cchar}), len, out)
    return String(strip(String(convert(Vector{UInt8},out)), '\0'))
end
