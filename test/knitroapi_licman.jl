
using KNITRO
using Test

@testset "License manager test" begin
    m = KNITRO.KN_new()
    KNITRO.KN_free(m)
    # create license manager context
    @show lm = KNITRO.LMcontext()

    # we create 10 KNITRO instances with the license manager
    n_instances = 10
    kcs = [KNITRO.KN_new_lm(lm) for i in 1:n_instances]

    # then we free the instances
    for kc in kcs
        KNITRO.KN_free(kc)
    end

    # and release the license
    KNITRO.KN_release_license(lm)
    @test lm.ptr_lmcontext == C_NULL
end

@testset "User params in newpoint callback with license manager (issue #151)" begin
    function callbackNewPoint(kc, x, duals, userParams)
        # Test that inputs are of valid type.
        @test isa(kc, KNITRO.Model)
        @test isa(x, Vector{Cdouble})
        @test isa(duals, Vector{Cdouble})
        return 0
    end
    # Instantiate license manager context.
    lm = KNITRO.LMcontext()
    # Test different values for userparams: nothing is the default value
    # so allows to test default Knitro behavior. "myuserparam" tries
    # setting a string userparam in Knitro.
    for userparam in [nothing, "myuserparam"]
        kc = KNITRO.KN_new_lm(lm)
        KNITRO.KN_set_int_param_by_name(kc, "outlev", 0)
        # At first, `newpoint_user` is nothing
        @test isnothing(kc.newpoint_user)
        p = Ref{Cint}()
        KNITRO.KN_add_var(kc, p)
        KNITRO.KN_set_var_lobnd(kc, Cint(0), 2.0)
        KNITRO.KN_set_var_primal_init_values_all(kc, [0.0])
        KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MINIMIZE)
        KNITRO.KN_add_obj_quadratic_struct(kc, 1, Cint[0], Cint[0], [1.0])
        KNITRO.KN_set_newpt_callback(kc, callbackNewPoint, userparam)
        # Test that userparam is correctly set
        @test kc.newpoint_user == userparam
        nstatus = KNITRO.KN_solve(kc)
        @test nstatus == KNITRO.KN_RC_OPTIMAL
        KNITRO.KN_free(kc)
    end
    KNITRO.KN_release_license(lm)
end
