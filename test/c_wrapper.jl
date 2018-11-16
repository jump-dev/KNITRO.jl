
using KNITRO
using Compat.Test

@testset "Knitro C interface" begin
    # get KNITRO release version
    rel = KNITRO.get_release()
    @test isa(rel, String)


    @testset "Definition of model" begin
        m = KNITRO.Model(KNITRO.Env())
        KNITRO.KN_load_param_file(m, "examples/knitro.opt")
        KNITRO.KN_reset_params_to_defaults(m)
    end
end
