# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

using KNITRO
using Test

@testset "License manager test" begin
    m = KN_new()
    KN_free(m)
    lm = KNITRO.LMcontext()
    kcs = [KN_new_lm(lm) for i in 1:10]
    for kc in kcs
        KN_free(kc)
    end
    KN_release_license(lm)
    @test lm.ptr_lmcontext == C_NULL
end

function newpt_callback(kc, x::Vector{Cdouble}, lambda::Vector{Cdouble}, user_data)
    @test kc isa KNITRO.Model
    return 0
end

@testset "User params in newpoint callback with license manager (issue #151)" begin
    lm = KNITRO.LMcontext()
    for user_data in (nothing, "myuserparam")
        kc = KN_new_lm(lm)
        KN_set_int_param_by_name(kc, "outlev", 0)
        p = Ref{Cint}()
        KN_add_var(kc, p)
        KN_set_var_lobnd(kc, Cint(0), 2.0)
        KN_set_var_primal_init_values_all(kc, [0.0])
        KN_set_obj_goal(kc, KN_OBJGOAL_MINIMIZE)
        KN_add_obj_quadratic_struct(kc, 1, Cint[0], Cint[0], [1.0])
        KN_set_newpt_callback(kc, newpt_callback, user_data)
        @test kc.newpt_user_data == user_data
        @test KN_solve(kc) == KN_RC_OPTIMAL
        KN_free(kc)
    end
    KN_release_license(lm)
end
