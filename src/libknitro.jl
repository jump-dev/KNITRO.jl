# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

const DBL_MAX = Float64(0x1.fffffffffffffp+1023)

const KNINT = Cint

const KNLONG = Clonglong

const KNBOOL = KNINT

const KN_context = Cvoid

const KN_context_ptr = Ptr{KN_context}

const LM_context = Cvoid

const LM_context_ptr = Ptr{LM_context}

function KN_get_release(length, release)
    @ccall libknitro.KN_get_release(length::Cint, release::Ptr{Cchar})::Cint
end

function KN_new(kc)
    @ccall libknitro.KN_new(kc::Ptr{KN_context_ptr})::Cint
end

function KN_free(kc)
    @ccall libknitro.KN_free(kc::Ptr{KN_context_ptr})::Cint
end

function KN_checkout_license(lmc)
    @ccall libknitro.KN_checkout_license(lmc::Ptr{LM_context_ptr})::Cint
end

function KN_new_lm(lmc, kc)
    @ccall libknitro.KN_new_lm(lmc::LM_context_ptr, kc::Ptr{KN_context_ptr})::Cint
end

function KN_release_license(lmc)
    @ccall libknitro.KN_release_license(lmc::Ptr{LM_context_ptr})::Cint
end

function KN_reset_params_to_defaults(kc)
    @ccall libknitro.KN_reset_params_to_defaults(kc::KN_context_ptr)::Cint
end

function KN_load_param_file(kc, filename)
    @ccall libknitro.KN_load_param_file(kc::KN_context_ptr, filename::Ptr{Cchar})::Cint
end

function KN_load_tuner_file(kc, filename)
    @ccall libknitro.KN_load_tuner_file(kc::KN_context_ptr, filename::Ptr{Cchar})::Cint
end

function KN_save_param_file(kc, filename)
    @ccall libknitro.KN_save_param_file(kc::KN_context_ptr, filename::Ptr{Cchar})::Cint
end

function KN_set_int_param_by_name(kc, name, value)
    @ccall libknitro.KN_set_int_param_by_name(
        kc::KN_context_ptr,
        name::Ptr{Cchar},
        value::Cint,
    )::Cint
end

function KN_set_char_param_by_name(kc, name, value)
    @ccall libknitro.KN_set_char_param_by_name(
        kc::KN_context_ptr,
        name::Ptr{Cchar},
        value::Ptr{Cchar},
    )::Cint
end

function KN_set_double_param_by_name(kc, name, value)
    @ccall libknitro.KN_set_double_param_by_name(
        kc::KN_context_ptr,
        name::Ptr{Cchar},
        value::Cdouble,
    )::Cint
end

function KN_set_param_by_name(kc, name, value)
    @ccall libknitro.KN_set_param_by_name(
        kc::KN_context_ptr,
        name::Ptr{Cchar},
        value::Cdouble,
    )::Cint
end

function KN_set_int_param(kc, param_id, value)
    @ccall libknitro.KN_set_int_param(kc::KN_context_ptr, param_id::Cint, value::Cint)::Cint
end

function KN_set_char_param(kc, param_id, value)
    @ccall libknitro.KN_set_char_param(
        kc::KN_context_ptr,
        param_id::Cint,
        value::Ptr{Cchar},
    )::Cint
end

function KN_set_double_param(kc, param_id, value)
    @ccall libknitro.KN_set_double_param(
        kc::KN_context_ptr,
        param_id::Cint,
        value::Cdouble,
    )::Cint
end

function KN_get_int_param_by_name(kc, name, value)
    @ccall libknitro.KN_get_int_param_by_name(
        kc::KN_context_ptr,
        name::Ptr{Cchar},
        value::Ptr{Cint},
    )::Cint
end

function KN_get_double_param_by_name(kc, name, value)
    @ccall libknitro.KN_get_double_param_by_name(
        kc::KN_context_ptr,
        name::Ptr{Cchar},
        value::Ptr{Cdouble},
    )::Cint
end

function KN_get_int_param(kc, param_id, value)
    @ccall libknitro.KN_get_int_param(
        kc::KN_context_ptr,
        param_id::Cint,
        value::Ptr{Cint},
    )::Cint
end

function KN_get_double_param(kc, param_id, value)
    @ccall libknitro.KN_get_double_param(
        kc::KN_context_ptr,
        param_id::Cint,
        value::Ptr{Cdouble},
    )::Cint
end

function KN_get_param_name(kc, param_id, param_name, output_size)
    @ccall libknitro.KN_get_param_name(
        kc::KN_context_ptr,
        param_id::Cint,
        param_name::Ptr{Cchar},
        output_size::Csize_t,
    )::Cint
end

function KN_get_param_doc(kc, param_id, description, output_size)
    @ccall libknitro.KN_get_param_doc(
        kc::KN_context_ptr,
        param_id::Cint,
        description::Ptr{Cchar},
        output_size::Csize_t,
    )::Cint
end

function KN_get_param_type(kc, param_id, param_type)
    @ccall libknitro.KN_get_param_type(
        kc::KN_context_ptr,
        param_id::Cint,
        param_type::Ptr{Cint},
    )::Cint
end

function KN_get_num_param_values(kc, param_id, num_param_values)
    @ccall libknitro.KN_get_num_param_values(
        kc::KN_context_ptr,
        param_id::Cint,
        num_param_values::Ptr{Cint},
    )::Cint
end

function KN_get_param_value_doc(kc, param_id, value_id, param_value_string, output_size)
    @ccall libknitro.KN_get_param_value_doc(
        kc::KN_context_ptr,
        param_id::Cint,
        value_id::Cint,
        param_value_string::Ptr{Cchar},
        output_size::Csize_t,
    )::Cint
end

function KN_get_param_value_doc_from_index(
    kc,
    param_id,
    value_index,
    param_value_string,
    output_size,
)
    @ccall libknitro.KN_get_param_value_doc_from_index(
        kc::KN_context_ptr,
        param_id::Cint,
        value_index::Cint,
        param_value_string::Ptr{Cchar},
        output_size::Csize_t,
    )::Cint
end

function KN_get_param_id(kc, name, param_id)
    @ccall libknitro.KN_get_param_id(
        kc::KN_context_ptr,
        name::Ptr{Cchar},
        param_id::Ptr{Cint},
    )::Cint
end

function KN_get_param_id_from_index(kc, param_id, param_index)
    @ccall libknitro.KN_get_param_id_from_index(
        kc::KN_context_ptr,
        param_id::Ptr{Cint},
        param_index::Cint,
    )::Cint
end

function KN_write_param_desc_file(kc, filepath)
    @ccall libknitro.KN_write_param_desc_file(
        kc::KN_context_ptr,
        filepath::Ptr{Cchar},
    )::Cint
end

function KN_add_vars(kc, nV, indexVars)
    @ccall libknitro.KN_add_vars(kc::KN_context_ptr, nV::KNINT, indexVars::Ptr{KNINT})::Cint
end

function KN_add_var(kc, indexVar)
    @ccall libknitro.KN_add_var(kc::KN_context_ptr, indexVar::Ptr{KNINT})::Cint
end

function KN_add_cons(kc, nC, indexCons)
    @ccall libknitro.KN_add_cons(kc::KN_context_ptr, nC::KNINT, indexCons::Ptr{KNINT})::Cint
end

function KN_add_con(kc, indexCon)
    @ccall libknitro.KN_add_con(kc::KN_context_ptr, indexCon::Ptr{KNINT})::Cint
end

function KN_add_rsds(kc, nR, indexRsds)
    @ccall libknitro.KN_add_rsds(kc::KN_context_ptr, nR::KNINT, indexRsds::Ptr{KNINT})::Cint
end

function KN_add_rsd(kc, indexRsd)
    @ccall libknitro.KN_add_rsd(kc::KN_context_ptr, indexRsd::Ptr{KNINT})::Cint
end

function KN_set_var_lobnds(kc, nV, indexVars, xLoBnds)
    @ccall libknitro.KN_set_var_lobnds(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xLoBnds::Ptr{Cdouble},
    )::Cint
end

function KN_set_var_lobnds_all(kc, xLoBnds)
    @ccall libknitro.KN_set_var_lobnds_all(kc::KN_context_ptr, xLoBnds::Ptr{Cdouble})::Cint
end

function KN_set_var_lobnd(kc, indexVar, xLoBnd)
    @ccall libknitro.KN_set_var_lobnd(
        kc::KN_context_ptr,
        indexVar::KNINT,
        xLoBnd::Cdouble,
    )::Cint
end

function KN_set_var_upbnds(kc, nV, indexVars, xUpBnds)
    @ccall libknitro.KN_set_var_upbnds(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xUpBnds::Ptr{Cdouble},
    )::Cint
end

function KN_set_var_upbnds_all(kc, xUpBnds)
    @ccall libknitro.KN_set_var_upbnds_all(kc::KN_context_ptr, xUpBnds::Ptr{Cdouble})::Cint
end

function KN_set_var_upbnd(kc, indexVar, xUpBnd)
    @ccall libknitro.KN_set_var_upbnd(
        kc::KN_context_ptr,
        indexVar::KNINT,
        xUpBnd::Cdouble,
    )::Cint
end

function KN_set_var_fxbnds(kc, nV, indexVars, xFxBnds)
    @ccall libknitro.KN_set_var_fxbnds(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xFxBnds::Ptr{Cdouble},
    )::Cint
end

function KN_set_var_fxbnds_all(kc, xFxBnds)
    @ccall libknitro.KN_set_var_fxbnds_all(kc::KN_context_ptr, xFxBnds::Ptr{Cdouble})::Cint
end

function KN_set_var_fxbnd(kc, indexVar, xFxBnd)
    @ccall libknitro.KN_set_var_fxbnd(
        kc::KN_context_ptr,
        indexVar::KNINT,
        xFxBnd::Cdouble,
    )::Cint
end

function KN_get_var_lobnds(kc, nV, indexVars, xLoBnds)
    @ccall libknitro.KN_get_var_lobnds(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xLoBnds::Ptr{Cdouble},
    )::Cint
end

function KN_get_var_lobnds_all(kc, xLoBnds)
    @ccall libknitro.KN_get_var_lobnds_all(kc::KN_context_ptr, xLoBnds::Ptr{Cdouble})::Cint
end

function KN_get_var_lobnd(kc, indexVar, xLoBnd)
    @ccall libknitro.KN_get_var_lobnd(
        kc::KN_context_ptr,
        indexVar::KNINT,
        xLoBnd::Ptr{Cdouble},
    )::Cint
end

function KN_get_var_upbnds(kc, nV, indexVars, xUpBnds)
    @ccall libknitro.KN_get_var_upbnds(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xUpBnds::Ptr{Cdouble},
    )::Cint
end

function KN_get_var_upbnds_all(kc, xUpBnds)
    @ccall libknitro.KN_get_var_upbnds_all(kc::KN_context_ptr, xUpBnds::Ptr{Cdouble})::Cint
end

function KN_get_var_upbnd(kc, indexVar, xUpBnd)
    @ccall libknitro.KN_get_var_upbnd(
        kc::KN_context_ptr,
        indexVar::KNINT,
        xUpBnd::Ptr{Cdouble},
    )::Cint
end

function KN_get_var_fxbnds(kc, nV, indexVars, xFxBnds)
    @ccall libknitro.KN_get_var_fxbnds(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xFxBnds::Ptr{Cdouble},
    )::Cint
end

function KN_get_var_fxbnds_all(kc, xFxBnds)
    @ccall libknitro.KN_get_var_fxbnds_all(kc::KN_context_ptr, xFxBnds::Ptr{Cdouble})::Cint
end

function KN_get_var_fxbnd(kc, indexVar, xFxBnd)
    @ccall libknitro.KN_get_var_fxbnd(
        kc::KN_context_ptr,
        indexVar::KNINT,
        xFxBnd::Ptr{Cdouble},
    )::Cint
end

function KN_set_var_types(kc, nV, indexVars, xTypes)
    @ccall libknitro.KN_set_var_types(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xTypes::Ptr{Cint},
    )::Cint
end

function KN_set_var_types_all(kc, xTypes)
    @ccall libknitro.KN_set_var_types_all(kc::KN_context_ptr, xTypes::Ptr{Cint})::Cint
end

function KN_set_var_type(kc, indexVar, xType)
    @ccall libknitro.KN_set_var_type(kc::KN_context_ptr, indexVar::KNINT, xType::Cint)::Cint
end

function KN_get_var_types(kc, nV, indexVars, xTypes)
    @ccall libknitro.KN_get_var_types(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xTypes::Ptr{Cint},
    )::Cint
end

function KN_get_var_types_all(kc, xTypes)
    @ccall libknitro.KN_get_var_types_all(kc::KN_context_ptr, xTypes::Ptr{Cint})::Cint
end

function KN_get_var_type(kc, indexVar, xType)
    @ccall libknitro.KN_get_var_type(
        kc::KN_context_ptr,
        indexVar::KNINT,
        xType::Ptr{Cint},
    )::Cint
end

function KN_set_var_properties(kc, nV, indexVars, xProperties)
    @ccall libknitro.KN_set_var_properties(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xProperties::Ptr{Cint},
    )::Cint
end

function KN_set_var_properties_all(kc, xProperties)
    @ccall libknitro.KN_set_var_properties_all(
        kc::KN_context_ptr,
        xProperties::Ptr{Cint},
    )::Cint
end

function KN_set_var_property(kc, indexVar, xProperty)
    @ccall libknitro.KN_set_var_property(
        kc::KN_context_ptr,
        indexVar::KNINT,
        xProperty::Cint,
    )::Cint
end

function KN_set_con_lobnds(kc, nC, indexCons, cLoBnds)
    @ccall libknitro.KN_set_con_lobnds(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        cLoBnds::Ptr{Cdouble},
    )::Cint
end

function KN_set_con_lobnds_all(kc, cLoBnds)
    @ccall libknitro.KN_set_con_lobnds_all(kc::KN_context_ptr, cLoBnds::Ptr{Cdouble})::Cint
end

function KN_set_con_lobnd(kc, indexCon, cLoBnd)
    @ccall libknitro.KN_set_con_lobnd(
        kc::KN_context_ptr,
        indexCon::KNINT,
        cLoBnd::Cdouble,
    )::Cint
end

function KN_set_con_upbnds(kc, nC, indexCons, cUpBnds)
    @ccall libknitro.KN_set_con_upbnds(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        cUpBnds::Ptr{Cdouble},
    )::Cint
end

function KN_set_con_upbnds_all(kc, cUpBnds)
    @ccall libknitro.KN_set_con_upbnds_all(kc::KN_context_ptr, cUpBnds::Ptr{Cdouble})::Cint
end

function KN_set_con_upbnd(kc, indexCon, cUpBnd)
    @ccall libknitro.KN_set_con_upbnd(
        kc::KN_context_ptr,
        indexCon::KNINT,
        cUpBnd::Cdouble,
    )::Cint
end

function KN_set_con_eqbnds(kc, nC, indexCons, cEqBnds)
    @ccall libknitro.KN_set_con_eqbnds(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        cEqBnds::Ptr{Cdouble},
    )::Cint
end

function KN_set_con_eqbnds_all(kc, cEqBnds)
    @ccall libknitro.KN_set_con_eqbnds_all(kc::KN_context_ptr, cEqBnds::Ptr{Cdouble})::Cint
end

function KN_set_con_eqbnd(kc, indexCon, cEqBnd)
    @ccall libknitro.KN_set_con_eqbnd(
        kc::KN_context_ptr,
        indexCon::KNINT,
        cEqBnd::Cdouble,
    )::Cint
end

function KN_get_con_lobnds(kc, nC, indexCons, cLoBnds)
    @ccall libknitro.KN_get_con_lobnds(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        cLoBnds::Ptr{Cdouble},
    )::Cint
end

function KN_get_con_lobnds_all(kc, cLoBnds)
    @ccall libknitro.KN_get_con_lobnds_all(kc::KN_context_ptr, cLoBnds::Ptr{Cdouble})::Cint
end

function KN_get_con_lobnd(kc, indexCon, cLoBnd)
    @ccall libknitro.KN_get_con_lobnd(
        kc::KN_context_ptr,
        indexCon::KNINT,
        cLoBnd::Ptr{Cdouble},
    )::Cint
end

function KN_get_con_upbnds(kc, nC, indexCons, cUpBnds)
    @ccall libknitro.KN_get_con_upbnds(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        cUpBnds::Ptr{Cdouble},
    )::Cint
end

function KN_get_con_upbnds_all(kc, cUpBnds)
    @ccall libknitro.KN_get_con_upbnds_all(kc::KN_context_ptr, cUpBnds::Ptr{Cdouble})::Cint
end

function KN_get_con_upbnd(kc, indexCon, cUpBnd)
    @ccall libknitro.KN_get_con_upbnd(
        kc::KN_context_ptr,
        indexCon::KNINT,
        cUpBnd::Ptr{Cdouble},
    )::Cint
end

function KN_get_con_eqbnds(kc, nC, indexCons, cEqBnds)
    @ccall libknitro.KN_get_con_eqbnds(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        cEqBnds::Ptr{Cdouble},
    )::Cint
end

function KN_get_con_eqbnds_all(kc, cEqBnds)
    @ccall libknitro.KN_get_con_eqbnds_all(kc::KN_context_ptr, cEqBnds::Ptr{Cdouble})::Cint
end

function KN_get_con_eqbnd(kc, indexCon, cEqBnd)
    @ccall libknitro.KN_get_con_eqbnd(
        kc::KN_context_ptr,
        indexCon::KNINT,
        cEqBnd::Ptr{Cdouble},
    )::Cint
end

function KN_set_obj_property(kc, objProperty)
    @ccall libknitro.KN_set_obj_property(kc::KN_context_ptr, objProperty::Cint)::Cint
end

function KN_set_con_properties(kc, nC, indexCons, cProperties)
    @ccall libknitro.KN_set_con_properties(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        cProperties::Ptr{Cint},
    )::Cint
end

function KN_set_con_properties_all(kc, cProperties)
    @ccall libknitro.KN_set_con_properties_all(
        kc::KN_context_ptr,
        cProperties::Ptr{Cint},
    )::Cint
end

function KN_set_con_property(kc, indexCon, cProperty)
    @ccall libknitro.KN_set_con_property(
        kc::KN_context_ptr,
        indexCon::KNINT,
        cProperty::Cint,
    )::Cint
end

function KN_set_obj_goal(kc, objGoal)
    @ccall libknitro.KN_set_obj_goal(kc::KN_context_ptr, objGoal::Cint)::Cint
end

function KN_get_obj_goal(kc, objGoal)
    @ccall libknitro.KN_get_obj_goal(kc::KN_context_ptr, objGoal::Ptr{Cint})::Cint
end

function KN_set_var_primal_init_values(kc, nV, indexVars, xInitVals)
    @ccall libknitro.KN_set_var_primal_init_values(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xInitVals::Ptr{Cdouble},
    )::Cint
end

function KN_set_var_primal_init_values_all(kc, xInitVals)
    @ccall libknitro.KN_set_var_primal_init_values_all(
        kc::KN_context_ptr,
        xInitVals::Ptr{Cdouble},
    )::Cint
end

function KN_set_var_primal_init_value(kc, indexVar, xInitVal)
    @ccall libknitro.KN_set_var_primal_init_value(
        kc::KN_context_ptr,
        indexVar::KNINT,
        xInitVal::Cdouble,
    )::Cint
end

function KN_set_var_dual_init_values(kc, nV, indexVars, lambdaInitVals)
    @ccall libknitro.KN_set_var_dual_init_values(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        lambdaInitVals::Ptr{Cdouble},
    )::Cint
end

function KN_set_var_dual_init_values_all(kc, lambdaInitVals)
    @ccall libknitro.KN_set_var_dual_init_values_all(
        kc::KN_context_ptr,
        lambdaInitVals::Ptr{Cdouble},
    )::Cint
end

function KN_set_var_dual_init_value(kc, indexVar, lambdaInitVal)
    @ccall libknitro.KN_set_var_dual_init_value(
        kc::KN_context_ptr,
        indexVar::KNINT,
        lambdaInitVal::Cdouble,
    )::Cint
end

function KN_set_con_dual_init_values(kc, nC, indexCons, lambdaInitVals)
    @ccall libknitro.KN_set_con_dual_init_values(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        lambdaInitVals::Ptr{Cdouble},
    )::Cint
end

function KN_set_con_dual_init_values_all(kc, lambdaInitVals)
    @ccall libknitro.KN_set_con_dual_init_values_all(
        kc::KN_context_ptr,
        lambdaInitVals::Ptr{Cdouble},
    )::Cint
end

function KN_set_con_dual_init_value(kc, indexCon, lambdaInitVal)
    @ccall libknitro.KN_set_con_dual_init_value(
        kc::KN_context_ptr,
        indexCon::KNINT,
        lambdaInitVal::Cdouble,
    )::Cint
end

function KN_add_obj_constant(kc, constant)
    @ccall libknitro.KN_add_obj_constant(kc::KN_context_ptr, constant::Cdouble)::Cint
end

function KN_del_obj_constant(kc)
    @ccall libknitro.KN_del_obj_constant(kc::KN_context_ptr)::Cint
end

function KN_chg_obj_constant(kc, constant)
    @ccall libknitro.KN_chg_obj_constant(kc::KN_context_ptr, constant::Cdouble)::Cint
end

function KN_add_con_constants(kc, nC, indexCons, constants)
    @ccall libknitro.KN_add_con_constants(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        constants::Ptr{Cdouble},
    )::Cint
end

function KN_add_con_constants_all(kc, constants)
    @ccall libknitro.KN_add_con_constants_all(
        kc::KN_context_ptr,
        constants::Ptr{Cdouble},
    )::Cint
end

function KN_add_con_constant(kc, indexCon, constant)
    @ccall libknitro.KN_add_con_constant(
        kc::KN_context_ptr,
        indexCon::KNINT,
        constant::Cdouble,
    )::Cint
end

function KN_del_con_constants(kc, nC, indexCons)
    @ccall libknitro.KN_del_con_constants(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
    )::Cint
end

function KN_del_con_constants_all(kc)
    @ccall libknitro.KN_del_con_constants_all(kc::KN_context_ptr)::Cint
end

function KN_del_con_constant(kc, indexCon)
    @ccall libknitro.KN_del_con_constant(kc::KN_context_ptr, indexCon::KNINT)::Cint
end

function KN_chg_con_constants(kc, nC, indexCons, constants)
    @ccall libknitro.KN_chg_con_constants(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        constants::Ptr{Cdouble},
    )::Cint
end

function KN_chg_con_constants_all(kc, constants)
    @ccall libknitro.KN_chg_con_constants_all(
        kc::KN_context_ptr,
        constants::Ptr{Cdouble},
    )::Cint
end

function KN_chg_con_constant(kc, indexCon, constant)
    @ccall libknitro.KN_chg_con_constant(
        kc::KN_context_ptr,
        indexCon::KNINT,
        constant::Cdouble,
    )::Cint
end

function KN_add_rsd_constants(kc, nR, indexRsds, constants)
    @ccall libknitro.KN_add_rsd_constants(
        kc::KN_context_ptr,
        nR::KNINT,
        indexRsds::Ptr{KNINT},
        constants::Ptr{Cdouble},
    )::Cint
end

function KN_add_rsd_constants_all(kc, constants)
    @ccall libknitro.KN_add_rsd_constants_all(
        kc::KN_context_ptr,
        constants::Ptr{Cdouble},
    )::Cint
end

function KN_add_rsd_constant(kc, indexRsd, constant)
    @ccall libknitro.KN_add_rsd_constant(
        kc::KN_context_ptr,
        indexRsd::KNINT,
        constant::Cdouble,
    )::Cint
end

function KN_add_obj_linear_struct(kc, nnz, indexVars, coefs)
    @ccall libknitro.KN_add_obj_linear_struct(
        kc::KN_context_ptr,
        nnz::KNINT,
        indexVars::Ptr{KNINT},
        coefs::Ptr{Cdouble},
    )::Cint
end

function KN_add_obj_linear_term(kc, indexVar, coef)
    @ccall libknitro.KN_add_obj_linear_term(
        kc::KN_context_ptr,
        indexVar::KNINT,
        coef::Cdouble,
    )::Cint
end

function KN_del_obj_linear_struct(kc, nnz, indexVars)
    @ccall libknitro.KN_del_obj_linear_struct(
        kc::KN_context_ptr,
        nnz::KNINT,
        indexVars::Ptr{KNINT},
    )::Cint
end

function KN_del_obj_linear_term(kc, indexVar)
    @ccall libknitro.KN_del_obj_linear_term(kc::KN_context_ptr, indexVar::KNINT)::Cint
end

function KN_del_obj_linear_struct_all(kc)
    @ccall libknitro.KN_del_obj_linear_struct_all(kc::KN_context_ptr)::Cint
end

function KN_chg_obj_linear_struct(kc, nnz, indexVars, coefs)
    @ccall libknitro.KN_chg_obj_linear_struct(
        kc::KN_context_ptr,
        nnz::KNINT,
        indexVars::Ptr{KNINT},
        coefs::Ptr{Cdouble},
    )::Cint
end

function KN_chg_obj_linear_term(kc, indexVar, coef)
    @ccall libknitro.KN_chg_obj_linear_term(
        kc::KN_context_ptr,
        indexVar::KNINT,
        coef::Cdouble,
    )::Cint
end

function KN_add_con_linear_struct(kc, nnz, indexCons, indexVars, coefs)
    @ccall libknitro.KN_add_con_linear_struct(
        kc::KN_context_ptr,
        nnz::KNLONG,
        indexCons::Ptr{KNINT},
        indexVars::Ptr{KNINT},
        coefs::Ptr{Cdouble},
    )::Cint
end

function KN_add_con_linear_struct_one(kc, nnz, indexCon, indexVars, coefs)
    @ccall libknitro.KN_add_con_linear_struct_one(
        kc::KN_context_ptr,
        nnz::KNLONG,
        indexCon::KNINT,
        indexVars::Ptr{KNINT},
        coefs::Ptr{Cdouble},
    )::Cint
end

function KN_add_con_linear_term(kc, indexCon, indexVar, coef)
    @ccall libknitro.KN_add_con_linear_term(
        kc::KN_context_ptr,
        indexCon::KNINT,
        indexVar::KNINT,
        coef::Cdouble,
    )::Cint
end

function KN_del_con_linear_struct(kc, nnz, indexCons, indexVars)
    @ccall libknitro.KN_del_con_linear_struct(
        kc::KN_context_ptr,
        nnz::KNLONG,
        indexCons::Ptr{KNINT},
        indexVars::Ptr{KNINT},
    )::Cint
end

function KN_del_con_linear_struct_one(kc, nnz, indexCon, indexVars)
    @ccall libknitro.KN_del_con_linear_struct_one(
        kc::KN_context_ptr,
        nnz::KNLONG,
        indexCon::KNINT,
        indexVars::Ptr{KNINT},
    )::Cint
end

function KN_del_con_linear_struct_all(kc, nC, indexCons)
    @ccall libknitro.KN_del_con_linear_struct_all(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
    )::Cint
end

function KN_del_con_linear_term(kc, indexCon, indexVar)
    @ccall libknitro.KN_del_con_linear_term(
        kc::KN_context_ptr,
        indexCon::KNINT,
        indexVar::KNINT,
    )::Cint
end

function KN_chg_con_linear_struct(kc, nnz, indexCons, indexVars, coefs)
    @ccall libknitro.KN_chg_con_linear_struct(
        kc::KN_context_ptr,
        nnz::KNLONG,
        indexCons::Ptr{KNINT},
        indexVars::Ptr{KNINT},
        coefs::Ptr{Cdouble},
    )::Cint
end

function KN_chg_con_linear_struct_one(kc, nnz, indexCon, indexVars, coefs)
    @ccall libknitro.KN_chg_con_linear_struct_one(
        kc::KN_context_ptr,
        nnz::KNLONG,
        indexCon::KNINT,
        indexVars::Ptr{KNINT},
        coefs::Ptr{Cdouble},
    )::Cint
end

function KN_chg_con_linear_term(kc, indexCon, indexVar, coef)
    @ccall libknitro.KN_chg_con_linear_term(
        kc::KN_context_ptr,
        indexCon::KNINT,
        indexVar::KNINT,
        coef::Cdouble,
    )::Cint
end

function KN_add_rsd_linear_struct(kc, nnz, indexRsds, indexVars, coefs)
    @ccall libknitro.KN_add_rsd_linear_struct(
        kc::KN_context_ptr,
        nnz::KNLONG,
        indexRsds::Ptr{KNINT},
        indexVars::Ptr{KNINT},
        coefs::Ptr{Cdouble},
    )::Cint
end

function KN_add_rsd_linear_struct_one(kc, nnz, indexRsd, indexVars, coefs)
    @ccall libknitro.KN_add_rsd_linear_struct_one(
        kc::KN_context_ptr,
        nnz::KNLONG,
        indexRsd::KNINT,
        indexVars::Ptr{KNINT},
        coefs::Ptr{Cdouble},
    )::Cint
end

function KN_add_rsd_linear_term(kc, indexRsd, indexVar, coef)
    @ccall libknitro.KN_add_rsd_linear_term(
        kc::KN_context_ptr,
        indexRsd::KNINT,
        indexVar::KNINT,
        coef::Cdouble,
    )::Cint
end

function KN_add_obj_quadratic_struct(kc, nnz, indexVars1, indexVars2, coefs)
    @ccall libknitro.KN_add_obj_quadratic_struct(
        kc::KN_context_ptr,
        nnz::KNLONG,
        indexVars1::Ptr{KNINT},
        indexVars2::Ptr{KNINT},
        coefs::Ptr{Cdouble},
    )::Cint
end

function KN_add_obj_quadratic_term(kc, indexVar1, indexVar2, coef)
    @ccall libknitro.KN_add_obj_quadratic_term(
        kc::KN_context_ptr,
        indexVar1::KNINT,
        indexVar2::KNINT,
        coef::Cdouble,
    )::Cint
end

function KN_del_obj_quadratic_struct(kc, nnz, indexVars1, indexVars2)
    @ccall libknitro.KN_del_obj_quadratic_struct(
        kc::KN_context_ptr,
        nnz::KNLONG,
        indexVars1::Ptr{KNINT},
        indexVars2::Ptr{KNINT},
    )::Cint
end

function KN_del_obj_quadratic_struct_all(kc)
    @ccall libknitro.KN_del_obj_quadratic_struct_all(kc::KN_context_ptr)::Cint
end

function KN_add_con_quadratic_struct(kc, nnz, indexCons, indexVars1, indexVars2, coefs)
    @ccall libknitro.KN_add_con_quadratic_struct(
        kc::KN_context_ptr,
        nnz::KNLONG,
        indexCons::Ptr{KNINT},
        indexVars1::Ptr{KNINT},
        indexVars2::Ptr{KNINT},
        coefs::Ptr{Cdouble},
    )::Cint
end

function KN_add_con_quadratic_struct_one(kc, nnz, indexCon, indexVars1, indexVars2, coefs)
    @ccall libknitro.KN_add_con_quadratic_struct_one(
        kc::KN_context_ptr,
        nnz::KNLONG,
        indexCon::KNINT,
        indexVars1::Ptr{KNINT},
        indexVars2::Ptr{KNINT},
        coefs::Ptr{Cdouble},
    )::Cint
end

function KN_add_con_quadratic_term(kc, indexCon, indexVar1, indexVar2, coef)
    @ccall libknitro.KN_add_con_quadratic_term(
        kc::KN_context_ptr,
        indexCon::KNINT,
        indexVar1::KNINT,
        indexVar2::KNINT,
        coef::Cdouble,
    )::Cint
end

function KN_del_con_quadratic_struct(kc, nnz, indexCons, indexVars1, indexVars2)
    @ccall libknitro.KN_del_con_quadratic_struct(
        kc::KN_context_ptr,
        nnz::KNLONG,
        indexCons::Ptr{KNINT},
        indexVars1::Ptr{KNINT},
        indexVars2::Ptr{KNINT},
    )::Cint
end

function KN_add_con_L2norm(
    kc,
    indexCon,
    nCoords,
    nnz,
    indexCoords,
    indexVars,
    coefs,
    constants,
)
    @ccall libknitro.KN_add_con_L2norm(
        kc::KN_context_ptr,
        indexCon::KNINT,
        nCoords::KNINT,
        nnz::KNLONG,
        indexCoords::Ptr{KNINT},
        indexVars::Ptr{KNINT},
        coefs::Ptr{Cdouble},
        constants::Ptr{Cdouble},
    )::Cint
end

function KN_add_compcons(kc, nCC, ccTypes, indexComps1, indexComps2, indexCompCons)
    @ccall libknitro.KN_add_compcons(
        kc::KN_context_ptr,
        nCC::KNINT,
        ccTypes::Ptr{Cint},
        indexComps1::Ptr{KNINT},
        indexComps2::Ptr{KNINT},
        indexCompCons::Ptr{KNINT},
    )::Cint
end

function KN_add_compcon(kc, ccType, indexComp1, indexComp2, indexCompCon)
    @ccall libknitro.KN_add_compcon(
        kc::KN_context_ptr,
        ccType::Cint,
        indexComp1::KNINT,
        indexComp2::KNINT,
        indexCompCon::Ptr{KNINT},
    )::Cint
end

function KN_set_compcons(kc, nCC, ccTypes, indexComps1, indexComps2)
    @ccall libknitro.KN_set_compcons(
        kc::KN_context_ptr,
        nCC::KNINT,
        ccTypes::Ptr{Cint},
        indexComps1::Ptr{KNINT},
        indexComps2::Ptr{KNINT},
    )::Cint
end

function KN_load_mps_file(kc, filename)
    @ccall libknitro.KN_load_mps_file(kc::KN_context_ptr, filename::Ptr{Cchar})::Cint
end

function KN_write_mps_file(kc, filename)
    @ccall libknitro.KN_write_mps_file(kc::KN_context_ptr, filename::Ptr{Cchar})::Cint
end

function KN_read_problem(kc, filename, read_options)
    @ccall libknitro.KN_read_problem(
        kc::KN_context_ptr,
        filename::Ptr{Cchar},
        read_options::Ptr{Cchar},
    )::Cint
end

function KN_write_problem(kc, filename, write_options)
    @ccall libknitro.KN_write_problem(
        kc::KN_context_ptr,
        filename::Ptr{Cchar},
        write_options::Ptr{Cchar},
    )::Cint
end

struct KN_eval_request
    type::Cint
    threadID::Cint
    x::Ptr{Cdouble}
    lambda::Ptr{Cdouble}
    sigma::Ptr{Cdouble}
    vec::Ptr{Cdouble}
end

const KN_eval_request_ptr = Ptr{KN_eval_request}

struct KN_eval_result
    obj::Ptr{Cdouble}
    c::Ptr{Cdouble}
    objGrad::Ptr{Cdouble}
    jac::Ptr{Cdouble}
    hess::Ptr{Cdouble}
    hessVec::Ptr{Cdouble}
    rsd::Ptr{Cdouble}
    rsdJac::Ptr{Cdouble}
end

const KN_eval_result_ptr = Ptr{KN_eval_result}

const CB_context = Cvoid

const CB_context_ptr = Ptr{CB_context}

# typedef int KN_eval_callback ( KN_context_ptr kc , CB_context_ptr cb , KN_eval_request_ptr const evalRequest , KN_eval_result_ptr const evalResult , void * const userParams )
const KN_eval_callback = Cvoid

function KN_add_eval_callback(kc, evalObj, nC, indexCons, funcCallback, cb)
    @ccall libknitro.KN_add_eval_callback(
        kc::KN_context_ptr,
        evalObj::KNBOOL,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        funcCallback::Ptr{KN_eval_callback},
        cb::Ptr{CB_context_ptr},
    )::Cint
end

function KN_add_eval_callback_all(kc, funcCallback, cb)
    @ccall libknitro.KN_add_eval_callback_all(
        kc::KN_context_ptr,
        funcCallback::Ptr{KN_eval_callback},
        cb::Ptr{CB_context_ptr},
    )::Cint
end

function KN_add_eval_callback_one(kc, index, funcCallback, cb)
    @ccall libknitro.KN_add_eval_callback_one(
        kc::KN_context_ptr,
        index::KNINT,
        funcCallback::Ptr{KN_eval_callback},
        cb::Ptr{CB_context_ptr},
    )::Cint
end

function KN_add_lsq_eval_callback(kc, nR, indexRsds, rsdCallback, cb)
    @ccall libknitro.KN_add_lsq_eval_callback(
        kc::KN_context_ptr,
        nR::KNINT,
        indexRsds::Ptr{KNINT},
        rsdCallback::Ptr{KN_eval_callback},
        cb::Ptr{CB_context_ptr},
    )::Cint
end

function KN_add_lsq_eval_callback_all(kc, rsdCallback, cb)
    @ccall libknitro.KN_add_lsq_eval_callback_all(
        kc::KN_context_ptr,
        rsdCallback::Ptr{KN_eval_callback},
        cb::Ptr{CB_context_ptr},
    )::Cint
end

function KN_add_lsq_eval_callback_one(kc, indexRsd, rsdCallback, cb)
    @ccall libknitro.KN_add_lsq_eval_callback_one(
        kc::KN_context_ptr,
        indexRsd::KNINT,
        rsdCallback::Ptr{KN_eval_callback},
        cb::Ptr{CB_context_ptr},
    )::Cint
end

function KN_set_cb_grad(
    kc,
    cb,
    nV,
    objGradIndexVars,
    nnzJ,
    jacIndexCons,
    jacIndexVars,
    gradCallback,
)
    @ccall libknitro.KN_set_cb_grad(
        kc::KN_context_ptr,
        cb::CB_context_ptr,
        nV::KNINT,
        objGradIndexVars::Ptr{KNINT},
        nnzJ::KNLONG,
        jacIndexCons::Ptr{KNINT},
        jacIndexVars::Ptr{KNINT},
        gradCallback::Ptr{KN_eval_callback},
    )::Cint
end

function KN_set_cb_hess(kc, cb, nnzH, hessIndexVars1, hessIndexVars2, hessCallback)
    @ccall libknitro.KN_set_cb_hess(
        kc::KN_context_ptr,
        cb::CB_context_ptr,
        nnzH::KNLONG,
        hessIndexVars1::Ptr{KNINT},
        hessIndexVars2::Ptr{KNINT},
        hessCallback::Ptr{KN_eval_callback},
    )::Cint
end

function KN_set_cb_rsd_jac(kc, cb, nnzJ, jacIndexRsds, jacIndexVars, rsdJacCallback)
    @ccall libknitro.KN_set_cb_rsd_jac(
        kc::KN_context_ptr,
        cb::CB_context_ptr,
        nnzJ::KNLONG,
        jacIndexRsds::Ptr{KNINT},
        jacIndexVars::Ptr{KNINT},
        rsdJacCallback::Ptr{KN_eval_callback},
    )::Cint
end

function KN_set_cb_user_params(kc, cb, userParams)
    @ccall libknitro.KN_set_cb_user_params(
        kc::KN_context_ptr,
        cb::CB_context_ptr,
        userParams::Ptr{Cvoid},
    )::Cint
end

function KN_set_cb_gradopt(kc, cb, gradopt)
    @ccall libknitro.KN_set_cb_gradopt(
        kc::KN_context_ptr,
        cb::CB_context_ptr,
        gradopt::Cint,
    )::Cint
end

function KN_set_cb_relstepsizes(kc, cb, nV, indexVars, xRelStepSizes)
    @ccall libknitro.KN_set_cb_relstepsizes(
        kc::KN_context_ptr,
        cb::CB_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xRelStepSizes::Ptr{Cdouble},
    )::Cint
end

function KN_set_cb_relstepsizes_all(kc, cb, xRelStepSizes)
    @ccall libknitro.KN_set_cb_relstepsizes_all(
        kc::KN_context_ptr,
        cb::CB_context_ptr,
        xRelStepSizes::Ptr{Cdouble},
    )::Cint
end

function KN_set_cb_relstepsize(kc, cb, indexVar, xRelStepSize)
    @ccall libknitro.KN_set_cb_relstepsize(
        kc::KN_context_ptr,
        cb::CB_context_ptr,
        indexVar::KNINT,
        xRelStepSize::Cdouble,
    )::Cint
end

function KN_get_cb_number_cons(kc, cb, nC)
    @ccall libknitro.KN_get_cb_number_cons(
        kc::KN_context_ptr,
        cb::CB_context_ptr,
        nC::Ptr{KNINT},
    )::Cint
end

function KN_get_cb_number_rsds(kc, cb, nR)
    @ccall libknitro.KN_get_cb_number_rsds(
        kc::KN_context_ptr,
        cb::CB_context_ptr,
        nR::Ptr{KNINT},
    )::Cint
end

function KN_get_cb_objgrad_nnz(kc, cb, nnz)
    @ccall libknitro.KN_get_cb_objgrad_nnz(
        kc::KN_context_ptr,
        cb::CB_context_ptr,
        nnz::Ptr{KNINT},
    )::Cint
end

function KN_get_cb_jacobian_nnz(kc, cb, nnz)
    @ccall libknitro.KN_get_cb_jacobian_nnz(
        kc::KN_context_ptr,
        cb::CB_context_ptr,
        nnz::Ptr{KNLONG},
    )::Cint
end

function KN_get_cb_rsd_jacobian_nnz(kc, cb, nnz)
    @ccall libknitro.KN_get_cb_rsd_jacobian_nnz(
        kc::KN_context_ptr,
        cb::CB_context_ptr,
        nnz::Ptr{KNLONG},
    )::Cint
end

function KN_get_cb_hessian_nnz(kc, cb, nnz)
    @ccall libknitro.KN_get_cb_hessian_nnz(
        kc::KN_context_ptr,
        cb::CB_context_ptr,
        nnz::Ptr{KNLONG},
    )::Cint
end

function KN_del_eval_callbacks(kc)
    @ccall libknitro.KN_del_eval_callbacks(kc::KN_context_ptr)::Cint
end

function KN_del_obj_eval_callback(kc, cb)
    @ccall libknitro.KN_del_obj_eval_callback(kc::KN_context_ptr, cb::CB_context_ptr)::Cint
end

function KN_del_obj_eval_callback_all(kc)
    @ccall libknitro.KN_del_obj_eval_callback_all(kc::KN_context_ptr)::Cint
end

# typedef int KN_user_callback ( KN_context_ptr kc , const double * const x , const double * const lambda , void * const userParams )
const KN_user_callback = Cvoid

function KN_set_newpt_callback(kc, fnPtr, userParams)
    @ccall libknitro.KN_set_newpt_callback(
        kc::KN_context_ptr,
        fnPtr::Ptr{KN_user_callback},
        userParams::Ptr{Cvoid},
    )::Cint
end

function KN_set_mip_node_callback(kc, fnPtr, userParams)
    @ccall libknitro.KN_set_mip_node_callback(
        kc::KN_context_ptr,
        fnPtr::Ptr{KN_user_callback},
        userParams::Ptr{Cvoid},
    )::Cint
end

function KN_set_mip_usercuts_callback(kc, fnPtr, userParams)
    @ccall libknitro.KN_set_mip_usercuts_callback(
        kc::KN_context_ptr,
        fnPtr::Ptr{KN_user_callback},
        userParams::Ptr{Cvoid},
    )::Cint
end

function KN_set_mip_lazyconstraints_callback(kc, fnPtr, userParams)
    @ccall libknitro.KN_set_mip_lazyconstraints_callback(
        kc::KN_context_ptr,
        fnPtr::Ptr{KN_user_callback},
        userParams::Ptr{Cvoid},
    )::Cint
end

function KN_set_ms_callback(kc, fnPtr, userParams)
    @ccall libknitro.KN_set_ms_callback(
        kc::KN_context_ptr,
        fnPtr::Ptr{KN_user_callback},
        userParams::Ptr{Cvoid},
    )::Cint
end

function KN_set_ms_process_callback(kc, fnPtr, userParams)
    @ccall libknitro.KN_set_ms_process_callback(
        kc::KN_context_ptr,
        fnPtr::Ptr{KN_user_callback},
        userParams::Ptr{Cvoid},
    )::Cint
end

# typedef int KN_ms_initpt_callback ( KN_context_ptr kc , const KNINT nSolveNumber , double * const x , double * const lambda , void * const userParams )
const KN_ms_initpt_callback = Cvoid

function KN_set_ms_initpt_callback(kc, fnPtr, userParams)
    @ccall libknitro.KN_set_ms_initpt_callback(
        kc::KN_context_ptr,
        fnPtr::Ptr{KN_ms_initpt_callback},
        userParams::Ptr{Cvoid},
    )::Cint
end

# typedef int KN_puts ( const char * const str , void * const userParams )
const KN_puts = Cvoid

function KN_set_puts_callback(kc, fnPtr, userParams)
    @ccall libknitro.KN_set_puts_callback(
        kc::KN_context_ptr,
        fnPtr::Ptr{KN_puts},
        userParams::Ptr{Cvoid},
    )::Cint
end

struct KN_linsolver_request
    phase::Cint
    linsysID::Cint
    threadID::Cint
    n::KNINT
    n11::KNINT
    rhs::Ptr{Cdouble}
    values::Ptr{Cdouble}
    indexRows::Ptr{KNINT}
    ptrCols::Ptr{KNLONG}
end

const KN_linsolver_request_ptr = Ptr{KN_linsolver_request}

struct KN_linsolver_result
    solution::Ptr{Cdouble}
    negeig::KNINT
    poseig::KNINT
    rank::KNINT
end

const KN_linsolver_result_ptr = Ptr{KN_linsolver_result}

# typedef int KN_linsolver_callback ( KN_context_ptr kc , KN_linsolver_request_ptr const linsolverRequest , KN_linsolver_result_ptr const linsolverResult , void * const userParams )
const KN_linsolver_callback = Cvoid

function KN_set_linsolver_callback(kc, fnPtr, userParams)
    @ccall libknitro.KN_set_linsolver_callback(
        kc::KN_context_ptr,
        fnPtr::Ptr{KN_linsolver_callback},
        userParams::Ptr{Cvoid},
    )::Cint
end

function KN_load_lp(
    kc,
    n,
    lobjCoefs,
    xLoBnds,
    xUpBnds,
    m,
    cLoBnds,
    cUpBnds,
    nnzJ,
    ljacIndexCons,
    ljacIndexVars,
    ljacCoefs,
)
    @ccall libknitro.KN_load_lp(
        kc::KN_context_ptr,
        n::KNINT,
        lobjCoefs::Ptr{Cdouble},
        xLoBnds::Ptr{Cdouble},
        xUpBnds::Ptr{Cdouble},
        m::KNINT,
        cLoBnds::Ptr{Cdouble},
        cUpBnds::Ptr{Cdouble},
        nnzJ::KNLONG,
        ljacIndexCons::Ptr{KNINT},
        ljacIndexVars::Ptr{KNINT},
        ljacCoefs::Ptr{Cdouble},
    )::Cint
end

function KN_load_qp(
    kc,
    n,
    lobjCoefs,
    xLoBnds,
    xUpBnds,
    m,
    cLoBnds,
    cUpBnds,
    nnzJ,
    ljacIndexCons,
    ljacIndexVars,
    ljacCoefs,
    nnzH,
    qobjIndexVars1,
    qobjIndexVars2,
    qobjCoefs,
)
    @ccall libknitro.KN_load_qp(
        kc::KN_context_ptr,
        n::KNINT,
        lobjCoefs::Ptr{Cdouble},
        xLoBnds::Ptr{Cdouble},
        xUpBnds::Ptr{Cdouble},
        m::KNINT,
        cLoBnds::Ptr{Cdouble},
        cUpBnds::Ptr{Cdouble},
        nnzJ::KNLONG,
        ljacIndexCons::Ptr{KNINT},
        ljacIndexVars::Ptr{KNINT},
        ljacCoefs::Ptr{Cdouble},
        nnzH::KNLONG,
        qobjIndexVars1::Ptr{KNINT},
        qobjIndexVars2::Ptr{KNINT},
        qobjCoefs::Ptr{Cdouble},
    )::Cint
end

function KN_load_qcqp(
    kc,
    n,
    lobjCoefs,
    xLoBnds,
    xUpBnds,
    m,
    cLoBnds,
    cUpBnds,
    nnzJ,
    ljacIndexCons,
    ljacIndexVars,
    ljacCoefs,
    nnzH,
    qobjIndexVars1,
    qobjIndexVars2,
    qobjCoefs,
    nnzQ,
    qconIndexCons,
    qconIndexVars1,
    qconIndexVars2,
    qconCoefs,
)
    @ccall libknitro.KN_load_qcqp(
        kc::KN_context_ptr,
        n::KNINT,
        lobjCoefs::Ptr{Cdouble},
        xLoBnds::Ptr{Cdouble},
        xUpBnds::Ptr{Cdouble},
        m::KNINT,
        cLoBnds::Ptr{Cdouble},
        cUpBnds::Ptr{Cdouble},
        nnzJ::KNLONG,
        ljacIndexCons::Ptr{KNINT},
        ljacIndexVars::Ptr{KNINT},
        ljacCoefs::Ptr{Cdouble},
        nnzH::KNLONG,
        qobjIndexVars1::Ptr{KNINT},
        qobjIndexVars2::Ptr{KNINT},
        qobjCoefs::Ptr{Cdouble},
        nnzQ::KNLONG,
        qconIndexCons::Ptr{KNINT},
        qconIndexVars1::Ptr{KNINT},
        qconIndexVars2::Ptr{KNINT},
        qconCoefs::Ptr{Cdouble},
    )::Cint
end

function KN_set_var_feastols(kc, nV, indexVars, xFeasTols)
    @ccall libknitro.KN_set_var_feastols(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xFeasTols::Ptr{Cdouble},
    )::Cint
end

function KN_set_var_feastols_all(kc, xFeasTols)
    @ccall libknitro.KN_set_var_feastols_all(
        kc::KN_context_ptr,
        xFeasTols::Ptr{Cdouble},
    )::Cint
end

function KN_set_var_feastol(kc, indexVar, xFeasTol)
    @ccall libknitro.KN_set_var_feastol(
        kc::KN_context_ptr,
        indexVar::KNINT,
        xFeasTol::Cdouble,
    )::Cint
end

function KN_set_con_feastols(kc, nC, indexCons, cFeasTols)
    @ccall libknitro.KN_set_con_feastols(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        cFeasTols::Ptr{Cdouble},
    )::Cint
end

function KN_set_con_feastols_all(kc, cFeasTols)
    @ccall libknitro.KN_set_con_feastols_all(
        kc::KN_context_ptr,
        cFeasTols::Ptr{Cdouble},
    )::Cint
end

function KN_set_con_feastol(kc, indexCon, cFeasTol)
    @ccall libknitro.KN_set_con_feastol(
        kc::KN_context_ptr,
        indexCon::KNINT,
        cFeasTol::Cdouble,
    )::Cint
end

function KN_set_compcon_feastols(kc, nCC, indexCompCons, ccFeasTols)
    @ccall libknitro.KN_set_compcon_feastols(
        kc::KN_context_ptr,
        nCC::KNINT,
        indexCompCons::Ptr{KNINT},
        ccFeasTols::Ptr{Cdouble},
    )::Cint
end

function KN_set_compcon_feastols_all(kc, ccFeasTols)
    @ccall libknitro.KN_set_compcon_feastols_all(
        kc::KN_context_ptr,
        ccFeasTols::Ptr{Cdouble},
    )::Cint
end

function KN_set_compcon_feastol(kc, indexCompCon, ccFeasTol)
    @ccall libknitro.KN_set_compcon_feastol(
        kc::KN_context_ptr,
        indexCompCon::KNINT,
        ccFeasTol::Cdouble,
    )::Cint
end

function KN_set_var_scalings(kc, nV, indexVars, xScaleFactors, xScaleCenters)
    @ccall libknitro.KN_set_var_scalings(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xScaleFactors::Ptr{Cdouble},
        xScaleCenters::Ptr{Cdouble},
    )::Cint
end

function KN_set_var_scalings_all(kc, xScaleFactors, xScaleCenters)
    @ccall libknitro.KN_set_var_scalings_all(
        kc::KN_context_ptr,
        xScaleFactors::Ptr{Cdouble},
        xScaleCenters::Ptr{Cdouble},
    )::Cint
end

function KN_set_var_scaling(kc, indexVar, xScaleFactor, xScaleCenter)
    @ccall libknitro.KN_set_var_scaling(
        kc::KN_context_ptr,
        indexVar::KNINT,
        xScaleFactor::Cdouble,
        xScaleCenter::Cdouble,
    )::Cint
end

function KN_set_con_scalings(kc, nC, indexCons, cScaleFactors)
    @ccall libknitro.KN_set_con_scalings(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        cScaleFactors::Ptr{Cdouble},
    )::Cint
end

function KN_set_con_scalings_all(kc, cScaleFactors)
    @ccall libknitro.KN_set_con_scalings_all(
        kc::KN_context_ptr,
        cScaleFactors::Ptr{Cdouble},
    )::Cint
end

function KN_set_con_scaling(kc, indexCon, cScaleFactor)
    @ccall libknitro.KN_set_con_scaling(
        kc::KN_context_ptr,
        indexCon::KNINT,
        cScaleFactor::Cdouble,
    )::Cint
end

function KN_set_compcon_scalings(kc, nCC, indexCompCons, ccScaleFactors)
    @ccall libknitro.KN_set_compcon_scalings(
        kc::KN_context_ptr,
        nCC::KNINT,
        indexCompCons::Ptr{KNINT},
        ccScaleFactors::Ptr{Cdouble},
    )::Cint
end

function KN_set_compcon_scalings_all(kc, ccScaleFactors)
    @ccall libknitro.KN_set_compcon_scalings_all(
        kc::KN_context_ptr,
        ccScaleFactors::Ptr{Cdouble},
    )::Cint
end

function KN_set_compcon_scaling(kc, indexCompCons, ccScaleFactor)
    @ccall libknitro.KN_set_compcon_scaling(
        kc::KN_context_ptr,
        indexCompCons::KNINT,
        ccScaleFactor::Cdouble,
    )::Cint
end

function KN_set_obj_scaling(kc, objScaleFactor)
    @ccall libknitro.KN_set_obj_scaling(kc::KN_context_ptr, objScaleFactor::Cdouble)::Cint
end

function KN_set_var_names(kc, nV, indexVars, xNames)
    @ccall libknitro.KN_set_var_names(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xNames::Ptr{Ptr{Cchar}},
    )::Cint
end

function KN_set_var_names_all(kc, xNames)
    @ccall libknitro.KN_set_var_names_all(kc::KN_context_ptr, xNames::Ptr{Ptr{Cchar}})::Cint
end

function KN_set_var_name(kc, indexVars, xName)
    @ccall libknitro.KN_set_var_name(
        kc::KN_context_ptr,
        indexVars::KNINT,
        xName::Ptr{Cchar},
    )::Cint
end

function KN_set_con_names(kc, nC, indexCons, cNames)
    @ccall libknitro.KN_set_con_names(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        cNames::Ptr{Ptr{Cchar}},
    )::Cint
end

function KN_set_con_names_all(kc, cNames)
    @ccall libknitro.KN_set_con_names_all(kc::KN_context_ptr, cNames::Ptr{Ptr{Cchar}})::Cint
end

function KN_set_con_name(kc, indexCon, cName)
    @ccall libknitro.KN_set_con_name(
        kc::KN_context_ptr,
        indexCon::KNINT,
        cName::Ptr{Cchar},
    )::Cint
end

function KN_set_compcon_names(kc, nCC, indexCompCons, ccNames)
    @ccall libknitro.KN_set_compcon_names(
        kc::KN_context_ptr,
        nCC::KNINT,
        indexCompCons::Ptr{KNINT},
        ccNames::Ptr{Ptr{Cchar}},
    )::Cint
end

function KN_set_compcon_names_all(kc, ccNames)
    @ccall libknitro.KN_set_compcon_names_all(
        kc::KN_context_ptr,
        ccNames::Ptr{Ptr{Cchar}},
    )::Cint
end

function KN_set_compcon_name(kc, indexCompCon, ccName)
    @ccall libknitro.KN_set_compcon_name(
        kc::KN_context_ptr,
        indexCompCon::Cint,
        ccName::Ptr{Cchar},
    )::Cint
end

function KN_set_obj_name(kc, objName)
    @ccall libknitro.KN_set_obj_name(kc::KN_context_ptr, objName::Ptr{Cchar})::Cint
end

function KN_get_var_names(kc, nV, indexVars, nBufferSize, xNames)
    @ccall libknitro.KN_get_var_names(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        nBufferSize::KNINT,
        xNames::Ptr{Ptr{Cchar}},
    )::Cint
end

function KN_get_var_names_all(kc, nBufferSize, xNames)
    @ccall libknitro.KN_get_var_names_all(
        kc::KN_context_ptr,
        nBufferSize::KNINT,
        xNames::Ptr{Ptr{Cchar}},
    )::Cint
end

function KN_get_var_name(kc, indexVars, nBufferSize, xName)
    @ccall libknitro.KN_get_var_name(
        kc::KN_context_ptr,
        indexVars::KNINT,
        nBufferSize::KNINT,
        xName::Ptr{Cchar},
    )::Cint
end

function KN_get_con_names(kc, nC, indexCons, nBufferSize, cNames)
    @ccall libknitro.KN_get_con_names(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        nBufferSize::KNINT,
        cNames::Ptr{Ptr{Cchar}},
    )::Cint
end

function KN_get_con_names_all(kc, nBufferSize, cNames)
    @ccall libknitro.KN_get_con_names_all(
        kc::KN_context_ptr,
        nBufferSize::KNINT,
        cNames::Ptr{Ptr{Cchar}},
    )::Cint
end

function KN_get_con_name(kc, indexCons, nBufferSize, cName)
    @ccall libknitro.KN_get_con_name(
        kc::KN_context_ptr,
        indexCons::KNINT,
        nBufferSize::KNINT,
        cName::Ptr{Cchar},
    )::Cint
end

function KN_get_obj_name(kc, nBufferSize, objName)
    @ccall libknitro.KN_get_obj_name(
        kc::KN_context_ptr,
        nBufferSize::KNINT,
        objName::Ptr{Cchar},
    )::Cint
end

function KN_set_var_honorbnds(kc, nV, indexVars, xHonorBnds)
    @ccall libknitro.KN_set_var_honorbnds(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xHonorBnds::Ptr{Cint},
    )::Cint
end

function KN_set_var_honorbnds_all(kc, xHonorBnds)
    @ccall libknitro.KN_set_var_honorbnds_all(
        kc::KN_context_ptr,
        xHonorBnds::Ptr{Cint},
    )::Cint
end

function KN_set_var_honorbnd(kc, indexVar, xHonorBnd)
    @ccall libknitro.KN_set_var_honorbnd(
        kc::KN_context_ptr,
        indexVar::KNINT,
        xHonorBnd::Cint,
    )::Cint
end

function KN_set_con_honorbnds(kc, nC, indexCons, cHonorBnds)
    @ccall libknitro.KN_set_con_honorbnds(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        cHonorBnds::Ptr{Cint},
    )::Cint
end

function KN_set_con_honorbnds_all(kc, cHonorBnds)
    @ccall libknitro.KN_set_con_honorbnds_all(
        kc::KN_context_ptr,
        cHonorBnds::Ptr{Cint},
    )::Cint
end

function KN_set_con_honorbnd(kc, indexCon, cHonorBnd)
    @ccall libknitro.KN_set_con_honorbnd(
        kc::KN_context_ptr,
        indexCon::KNINT,
        cHonorBnd::Cint,
    )::Cint
end

function KN_set_mip_var_primal_init_values(kc, nV, indexVars, xInitVals)
    @ccall libknitro.KN_set_mip_var_primal_init_values(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xInitVals::Ptr{Cdouble},
    )::Cint
end

function KN_set_mip_var_primal_init_values_all(kc, xInitVals)
    @ccall libknitro.KN_set_mip_var_primal_init_values_all(
        kc::KN_context_ptr,
        xInitVals::Ptr{Cdouble},
    )::Cint
end

function KN_set_mip_var_primal_init_value(kc, indexVar, xInitVal)
    @ccall libknitro.KN_set_mip_var_primal_init_value(
        kc::KN_context_ptr,
        indexVar::KNINT,
        xInitVal::Cdouble,
    )::Cint
end

function KN_set_mip_branching_priorities(kc, nV, indexVars, xPriorities)
    @ccall libknitro.KN_set_mip_branching_priorities(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xPriorities::Ptr{Cint},
    )::Cint
end

function KN_set_mip_branching_priorities_all(kc, xPriorities)
    @ccall libknitro.KN_set_mip_branching_priorities_all(
        kc::KN_context_ptr,
        xPriorities::Ptr{Cint},
    )::Cint
end

function KN_set_mip_branching_priority(kc, indexVar, xPriority)
    @ccall libknitro.KN_set_mip_branching_priority(
        kc::KN_context_ptr,
        indexVar::KNINT,
        xPriority::Cint,
    )::Cint
end

function KN_set_mip_intvar_strategies(kc, nV, indexVars, xStrategies)
    @ccall libknitro.KN_set_mip_intvar_strategies(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        xStrategies::Ptr{Cint},
    )::Cint
end

function KN_set_mip_intvar_strategies_all(kc, xStrategies)
    @ccall libknitro.KN_set_mip_intvar_strategies_all(
        kc::KN_context_ptr,
        xStrategies::Ptr{Cint},
    )::Cint
end

function KN_set_mip_intvar_strategy(kc, indexVar, xStrategy)
    @ccall libknitro.KN_set_mip_intvar_strategy(
        kc::KN_context_ptr,
        indexVar::KNINT,
        xStrategy::Cint,
    )::Cint
end

function KN_solve(kc)
    @ccall libknitro.KN_solve(kc::KN_context_ptr)::Cint
end

function KN_update(kc)
    @ccall libknitro.KN_update(kc::KN_context_ptr)::Cint
end

function KN_get_number_vars(kc, nV)
    @ccall libknitro.KN_get_number_vars(kc::KN_context_ptr, nV::Ptr{KNINT})::Cint
end

function KN_get_number_cons(kc, nC)
    @ccall libknitro.KN_get_number_cons(kc::KN_context_ptr, nC::Ptr{KNINT})::Cint
end

function KN_get_number_compcons(kc, nCC)
    @ccall libknitro.KN_get_number_compcons(kc::KN_context_ptr, nCC::Ptr{KNINT})::Cint
end

function KN_get_number_rsds(kc, nR)
    @ccall libknitro.KN_get_number_rsds(kc::KN_context_ptr, nR::Ptr{KNINT})::Cint
end

function KN_get_number_FC_evals(kc, numFCevals)
    @ccall libknitro.KN_get_number_FC_evals(kc::KN_context_ptr, numFCevals::Ptr{Cint})::Cint
end

function KN_get_number_GA_evals(kc, numGAevals)
    @ccall libknitro.KN_get_number_GA_evals(kc::KN_context_ptr, numGAevals::Ptr{Cint})::Cint
end

function KN_get_number_H_evals(kc, numHevals)
    @ccall libknitro.KN_get_number_H_evals(kc::KN_context_ptr, numHevals::Ptr{Cint})::Cint
end

function KN_get_number_HV_evals(kc, numHVevals)
    @ccall libknitro.KN_get_number_HV_evals(kc::KN_context_ptr, numHVevals::Ptr{Cint})::Cint
end

function KN_get_solve_time_cpu(kc, time)
    @ccall libknitro.KN_get_solve_time_cpu(kc::KN_context_ptr, time::Ptr{Cdouble})::Cint
end

function KN_get_solve_time_real(kc, time)
    @ccall libknitro.KN_get_solve_time_real(kc::KN_context_ptr, time::Ptr{Cdouble})::Cint
end

function KN_get_solution(kc, status, obj, x, lambda)
    @ccall libknitro.KN_get_solution(
        kc::KN_context_ptr,
        status::Ptr{Cint},
        obj::Ptr{Cdouble},
        x::Ptr{Cdouble},
        lambda::Ptr{Cdouble},
    )::Cint
end

function KN_get_best_feasible_iterate(kc, feasError, obj, x, lambda, c)
    @ccall libknitro.KN_get_best_feasible_iterate(
        kc::KN_context_ptr,
        feasError::Ptr{Cdouble},
        obj::Ptr{Cdouble},
        x::Ptr{Cdouble},
        lambda::Ptr{Cdouble},
        c::Ptr{Cdouble},
    )::Cint
end

function KN_get_obj_value(kc, obj)
    @ccall libknitro.KN_get_obj_value(kc::KN_context_ptr, obj::Ptr{Cdouble})::Cint
end

function KN_get_obj_type(kc, objType)
    @ccall libknitro.KN_get_obj_type(kc::KN_context_ptr, objType::Ptr{Cint})::Cint
end

function KN_get_var_primal_values(kc, nV, indexVars, x)
    @ccall libknitro.KN_get_var_primal_values(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        x::Ptr{Cdouble},
    )::Cint
end

function KN_get_var_primal_values_all(kc, x)
    @ccall libknitro.KN_get_var_primal_values_all(kc::KN_context_ptr, x::Ptr{Cdouble})::Cint
end

function KN_get_var_primal_value(kc, indexVar, x)
    @ccall libknitro.KN_get_var_primal_value(
        kc::KN_context_ptr,
        indexVar::KNINT,
        x::Ptr{Cdouble},
    )::Cint
end

function KN_get_var_dual_values(kc, nV, indexVars, lambda)
    @ccall libknitro.KN_get_var_dual_values(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        lambda::Ptr{Cdouble},
    )::Cint
end

function KN_get_var_dual_values_all(kc, lambda)
    @ccall libknitro.KN_get_var_dual_values_all(
        kc::KN_context_ptr,
        lambda::Ptr{Cdouble},
    )::Cint
end

function KN_get_var_dual_value(kc, indexVar, lambda)
    @ccall libknitro.KN_get_var_dual_value(
        kc::KN_context_ptr,
        indexVar::KNINT,
        lambda::Ptr{Cdouble},
    )::Cint
end

function KN_get_con_dual_values(kc, nC, indexCons, lambda)
    @ccall libknitro.KN_get_con_dual_values(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        lambda::Ptr{Cdouble},
    )::Cint
end

function KN_get_con_dual_values_all(kc, lambda)
    @ccall libknitro.KN_get_con_dual_values_all(
        kc::KN_context_ptr,
        lambda::Ptr{Cdouble},
    )::Cint
end

function KN_get_con_dual_value(kc, indexCons, lambda)
    @ccall libknitro.KN_get_con_dual_value(
        kc::KN_context_ptr,
        indexCons::KNINT,
        lambda::Ptr{Cdouble},
    )::Cint
end

function KN_get_con_values(kc, nC, indexCons, c)
    @ccall libknitro.KN_get_con_values(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        c::Ptr{Cdouble},
    )::Cint
end

function KN_get_con_values_all(kc, c)
    @ccall libknitro.KN_get_con_values_all(kc::KN_context_ptr, c::Ptr{Cdouble})::Cint
end

function KN_get_con_value(kc, indexCon, c)
    @ccall libknitro.KN_get_con_value(
        kc::KN_context_ptr,
        indexCon::KNINT,
        c::Ptr{Cdouble},
    )::Cint
end

function KN_get_con_types(kc, nC, indexCons, cTypes)
    @ccall libknitro.KN_get_con_types(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        cTypes::Ptr{Cint},
    )::Cint
end

function KN_get_con_types_all(kc, cTypes)
    @ccall libknitro.KN_get_con_types_all(kc::KN_context_ptr, cTypes::Ptr{Cint})::Cint
end

function KN_get_con_type(kc, indexCon, cType)
    @ccall libknitro.KN_get_con_type(
        kc::KN_context_ptr,
        indexCon::KNINT,
        cType::Ptr{Cint},
    )::Cint
end

function KN_get_rsd_values(kc, nR, indexRsds, r)
    @ccall libknitro.KN_get_rsd_values(
        kc::KN_context_ptr,
        nR::KNINT,
        indexRsds::Ptr{KNINT},
        r::Ptr{Cdouble},
    )::Cint
end

function KN_get_rsd_values_all(kc, r)
    @ccall libknitro.KN_get_rsd_values_all(kc::KN_context_ptr, r::Ptr{Cdouble})::Cint
end

function KN_get_rsd_value(kc, indexRsd, r)
    @ccall libknitro.KN_get_rsd_value(
        kc::KN_context_ptr,
        indexRsd::KNINT,
        r::Ptr{Cdouble},
    )::Cint
end

function KN_get_var_viols(kc, nV, indexVars, bndInfeas, intInfeas, viols)
    @ccall libknitro.KN_get_var_viols(
        kc::KN_context_ptr,
        nV::KNINT,
        indexVars::Ptr{KNINT},
        bndInfeas::Ptr{KNINT},
        intInfeas::Ptr{KNINT},
        viols::Ptr{Cdouble},
    )::Cint
end

function KN_get_var_viols_all(kc, bndInfeas, intInfeas, viols)
    @ccall libknitro.KN_get_var_viols_all(
        kc::KN_context_ptr,
        bndInfeas::Ptr{KNINT},
        intInfeas::Ptr{KNINT},
        viols::Ptr{Cdouble},
    )::Cint
end

function KN_get_var_viol(kc, indexVar, bndInfeas, intInfeas, viol)
    @ccall libknitro.KN_get_var_viol(
        kc::KN_context_ptr,
        indexVar::KNINT,
        bndInfeas::Ptr{KNINT},
        intInfeas::Ptr{KNINT},
        viol::Ptr{Cdouble},
    )::Cint
end

function KN_get_con_viols(kc, nC, indexCons, infeas, viols)
    @ccall libknitro.KN_get_con_viols(
        kc::KN_context_ptr,
        nC::KNINT,
        indexCons::Ptr{KNINT},
        infeas::Ptr{KNINT},
        viols::Ptr{Cdouble},
    )::Cint
end

function KN_get_con_viols_all(kc, infeas, viols)
    @ccall libknitro.KN_get_con_viols_all(
        kc::KN_context_ptr,
        infeas::Ptr{KNINT},
        viols::Ptr{Cdouble},
    )::Cint
end

function KN_get_con_viol(kc, indexCon, infeas, viol)
    @ccall libknitro.KN_get_con_viol(
        kc::KN_context_ptr,
        indexCon::KNINT,
        infeas::Ptr{KNINT},
        viol::Ptr{Cdouble},
    )::Cint
end

function KN_get_presolve_error(kc, component, index, error, viol)
    @ccall libknitro.KN_get_presolve_error(
        kc::KN_context_ptr,
        component::Ptr{KNINT},
        index::Ptr{KNINT},
        error::Ptr{KNINT},
        viol::Ptr{Cdouble},
    )::Cint
end

function KN_get_number_iters(kc, numIters)
    @ccall libknitro.KN_get_number_iters(kc::KN_context_ptr, numIters::Ptr{Cint})::Cint
end

function KN_get_number_cg_iters(kc, numCGiters)
    @ccall libknitro.KN_get_number_cg_iters(kc::KN_context_ptr, numCGiters::Ptr{Cint})::Cint
end

function KN_get_abs_feas_error(kc, absFeasError)
    @ccall libknitro.KN_get_abs_feas_error(
        kc::KN_context_ptr,
        absFeasError::Ptr{Cdouble},
    )::Cint
end

function KN_get_rel_feas_error(kc, relFeasError)
    @ccall libknitro.KN_get_rel_feas_error(
        kc::KN_context_ptr,
        relFeasError::Ptr{Cdouble},
    )::Cint
end

function KN_get_abs_opt_error(kc, absOptError)
    @ccall libknitro.KN_get_abs_opt_error(
        kc::KN_context_ptr,
        absOptError::Ptr{Cdouble},
    )::Cint
end

function KN_get_rel_opt_error(kc, relOptError)
    @ccall libknitro.KN_get_rel_opt_error(
        kc::KN_context_ptr,
        relOptError::Ptr{Cdouble},
    )::Cint
end

function KN_get_objgrad_nnz(kc, nnz)
    @ccall libknitro.KN_get_objgrad_nnz(kc::KN_context_ptr, nnz::Ptr{KNINT})::Cint
end

function KN_get_objgrad_values(kc, indexVars, objGrad)
    @ccall libknitro.KN_get_objgrad_values(
        kc::KN_context_ptr,
        indexVars::Ptr{KNINT},
        objGrad::Ptr{Cdouble},
    )::Cint
end

function KN_get_objgrad_values_all(kc, objGrad)
    @ccall libknitro.KN_get_objgrad_values_all(
        kc::KN_context_ptr,
        objGrad::Ptr{Cdouble},
    )::Cint
end

function KN_get_jacobian_nnz(kc, nnz)
    @ccall libknitro.KN_get_jacobian_nnz(kc::KN_context_ptr, nnz::Ptr{KNLONG})::Cint
end

function KN_get_jacobian_values(kc, indexCons, indexVars, jac)
    @ccall libknitro.KN_get_jacobian_values(
        kc::KN_context_ptr,
        indexCons::Ptr{KNINT},
        indexVars::Ptr{KNINT},
        jac::Ptr{Cdouble},
    )::Cint
end

function KN_get_jacobian_nnz_one(kc, indexCon, nnz)
    @ccall libknitro.KN_get_jacobian_nnz_one(
        kc::KN_context_ptr,
        indexCon::KNINT,
        nnz::Ptr{KNINT},
    )::Cint
end

function KN_get_jacobian_values_one(kc, indexCon, indexVars, jac)
    @ccall libknitro.KN_get_jacobian_values_one(
        kc::KN_context_ptr,
        indexCon::KNINT,
        indexVars::Ptr{KNINT},
        jac::Ptr{Cdouble},
    )::Cint
end

function KN_get_rsd_jacobian_nnz(kc, nnz)
    @ccall libknitro.KN_get_rsd_jacobian_nnz(kc::KN_context_ptr, nnz::Ptr{KNLONG})::Cint
end

function KN_get_rsd_jacobian_values(kc, indexRsds, indexVars, rsdJac)
    @ccall libknitro.KN_get_rsd_jacobian_values(
        kc::KN_context_ptr,
        indexRsds::Ptr{KNINT},
        indexVars::Ptr{KNINT},
        rsdJac::Ptr{Cdouble},
    )::Cint
end

function KN_get_hessian_nnz(kc, nnz)
    @ccall libknitro.KN_get_hessian_nnz(kc::KN_context_ptr, nnz::Ptr{KNLONG})::Cint
end

function KN_get_hessian_values(kc, indexVars1, indexVars2, hess)
    @ccall libknitro.KN_get_hessian_values(
        kc::KN_context_ptr,
        indexVars1::Ptr{KNINT},
        indexVars2::Ptr{KNINT},
        hess::Ptr{Cdouble},
    )::Cint
end

function KN_get_mip_number_nodes(kc, numNodes)
    @ccall libknitro.KN_get_mip_number_nodes(kc::KN_context_ptr, numNodes::Ptr{Cint})::Cint
end

function KN_get_mip_number_solves(kc, numSolves)
    @ccall libknitro.KN_get_mip_number_solves(
        kc::KN_context_ptr,
        numSolves::Ptr{Cint},
    )::Cint
end

function KN_get_mip_abs_gap(kc, absGap)
    @ccall libknitro.KN_get_mip_abs_gap(kc::KN_context_ptr, absGap::Ptr{Cdouble})::Cint
end

function KN_get_mip_rel_gap(kc, relGap)
    @ccall libknitro.KN_get_mip_rel_gap(kc::KN_context_ptr, relGap::Ptr{Cdouble})::Cint
end

function KN_get_mip_incumbent_obj(kc, incumbentObj)
    @ccall libknitro.KN_get_mip_incumbent_obj(
        kc::KN_context_ptr,
        incumbentObj::Ptr{Cdouble},
    )::Cint
end

function KN_get_mip_relaxation_bnd(kc, relaxBound)
    @ccall libknitro.KN_get_mip_relaxation_bnd(
        kc::KN_context_ptr,
        relaxBound::Ptr{Cdouble},
    )::Cint
end

function KN_get_mip_lastnode_obj(kc, lastNodeObj)
    @ccall libknitro.KN_get_mip_lastnode_obj(
        kc::KN_context_ptr,
        lastNodeObj::Ptr{Cdouble},
    )::Cint
end

function KN_get_mip_incumbent_x(kc, x)
    @ccall libknitro.KN_get_mip_incumbent_x(kc::KN_context_ptr, x::Ptr{Cdouble})::Cint
end

const TRUE = 1

const FALSE = 0

# Skipping MacroDefinition: KNITRO_API __attribute__ ( ( visibility ( "default" ) ) )

const KNTRUE = 1

const KNFALSE = 0

const KN_LINSOLVER_PHASE_INIT = 0

const KN_LINSOLVER_PHASE_ANALYZE = 1

const KN_LINSOLVER_PHASE_FACTOR = 2

const KN_LINSOLVER_PHASE_SOLVE = 3

const KN_LINSOLVER_PHASE_FREE = 4

const KN_INFINITY = DBL_MAX

const KN_PARAMTYPE_INTEGER = 0

const KN_PARAMTYPE_FLOAT = 1

const KN_PARAMTYPE_STRING = 2

const KN_COMPONENT_VAR = 1

const KN_COMPONENT_OBJ = 2

const KN_COMPONENT_CON = 3

const KN_COMPONENT_RSD = 4

const KN_OBJGOAL_MINIMIZE = 0

const KN_OBJGOAL_MAXIMIZE = 1

const KN_OBJTYPE_CONSTANT = -1

const KN_OBJTYPE_GENERAL = 0

const KN_OBJTYPE_LINEAR = 1

const KN_OBJTYPE_QUADRATIC = 2

const KN_CONTYPE_CONSTANT = -1

const KN_CONTYPE_GENERAL = 0

const KN_CONTYPE_LINEAR = 1

const KN_CONTYPE_QUADRATIC = 2

const KN_CONTYPE_CONIC = 3

const KN_RSDTYPE_CONSTANT = -1

const KN_RSDTYPE_GENERAL = 0

const KN_RSDTYPE_LINEAR = 1

const KN_CCTYPE_VARVAR = 0

const KN_CCTYPE_VARCON = 1

const KN_CCTYPE_CONCON = 2

const KN_VARTYPE_CONTINUOUS = 0

const KN_VARTYPE_INTEGER = 1

const KN_VARTYPE_BINARY = 2

const KN_VAR_LINEAR = 1

const KN_OBJ_CONVEX = 1

const KN_OBJ_CONCAVE = 2

const KN_OBJ_CONTINUOUS = 4

const KN_OBJ_DIFFERENTIABLE = 8

const KN_OBJ_TWICE_DIFFERENTIABLE = 16

const KN_OBJ_NOISY = 32

const KN_OBJ_NONDETERMINISTIC = 64

const KN_CON_CONVEX = 1

const KN_CON_CONCAVE = 2

const KN_CON_CONTINUOUS = 4

const KN_CON_DIFFERENTIABLE = 8

const KN_CON_TWICE_DIFFERENTIABLE = 16

const KN_CON_NOISY = 32

const KN_CON_NONDETERMINISTIC = 64

const KN_DENSE = -1

const KN_DENSE_ROWMAJOR = -2

const KN_DENSE_COLMAJOR = -3

const KN_RC_EVALFC = 1

const KN_RC_EVALGA = 2

const KN_RC_EVALH = 3

const KN_RC_EVALHV = 7

const KN_RC_EVALH_NO_F = 8

const KN_RC_EVALHV_NO_F = 9

const KN_RC_EVALR = 10

const KN_RC_EVALRJ = 11

const KN_RC_EVALFCGA = 12

const KN_RC_OPTIMAL_OR_SATISFACTORY = 0

const KN_RC_OPTIMAL = 0

const KN_RC_NEAR_OPT = -100

const KN_RC_FEAS_XTOL = -101

const KN_RC_FEAS_NO_IMPROVE = -102

const KN_RC_FEAS_FTOL = -103

const KN_RC_FEAS_BEST = -104

const KN_RC_FEAS_MULTISTART = -105

const KN_RC_INFEASIBLE = -200

const KN_RC_INFEAS_XTOL = -201

const KN_RC_INFEAS_NO_IMPROVE = -202

const KN_RC_INFEAS_MULTISTART = -203

const KN_RC_INFEAS_CON_BOUNDS = -204

const KN_RC_INFEAS_VAR_BOUNDS = -205

const KN_RC_UNBOUNDED = -300

const KN_RC_UNBOUNDED_OR_INFEAS = -301

const KN_RC_ITER_LIMIT_FEAS = -400

const KN_RC_TIME_LIMIT_FEAS = -401

const KN_RC_FEVAL_LIMIT_FEAS = -402

const KN_RC_MIP_EXH_FEAS = -403

const KN_RC_MIP_TERM_FEAS = -404

const KN_RC_MIP_SOLVE_LIMIT_FEAS = -405

const KN_RC_MIP_NODE_LIMIT_FEAS = -406

const KN_RC_ITER_LIMIT_INFEAS = -410

const KN_RC_TIME_LIMIT_INFEAS = -411

const KN_RC_FEVAL_LIMIT_INFEAS = -412

const KN_RC_MIP_EXH_INFEAS = -413

const KN_RC_MIP_SOLVE_LIMIT_INFEAS = -415

const KN_RC_MIP_NODE_LIMIT_INFEAS = -416

const KN_RC_CALLBACK_ERR = -500

const KN_RC_LP_SOLVER_ERR = -501

const KN_RC_EVAL_ERR = -502

const KN_RC_OUT_OF_MEMORY = -503

const KN_RC_USER_TERMINATION = -504

const KN_RC_OPEN_FILE_ERR = -505

const KN_RC_BAD_N_OR_F = -506

const KN_RC_BAD_CONSTRAINT = -507

const KN_RC_BAD_JACOBIAN = -508

const KN_RC_BAD_HESSIAN = -509

const KN_RC_BAD_CON_INDEX = -510

const KN_RC_BAD_JAC_INDEX = -511

const KN_RC_BAD_HESS_INDEX = -512

const KN_RC_BAD_CON_BOUNDS = -513

const KN_RC_BAD_VAR_BOUNDS = -514

const KN_RC_ILLEGAL_CALL = -515

const KN_RC_BAD_KCPTR = -516

const KN_RC_NULL_POINTER = -517

const KN_RC_BAD_INIT_VALUE = -518

const KN_RC_LICENSE_ERROR = -520

const KN_RC_BAD_PARAMINPUT = -521

const KN_RC_LINEAR_SOLVER_ERR = -522

const KN_RC_DERIV_CHECK_FAILED = -523

const KN_RC_DERIV_CHECK_TERMINATE = -524

const KN_RC_OVERFLOW_ERR = -525

const KN_RC_BAD_SIZE = -526

const KN_RC_BAD_VARIABLE = -527

const KN_RC_BAD_VAR_INDEX = -528

const KN_RC_BAD_OBJECTIVE = -529

const KN_RC_BAD_OBJ_INDEX = -530

const KN_RC_BAD_RESIDUAL = -531

const KN_RC_BAD_RSD_INDEX = -532

const KN_RC_INTERNAL_ERROR = -600

const KN_PARAM_NEWPOINT = 1001

const KN_NEWPOINT_NONE = 0

const KN_NEWPOINT_SAVEONE = 1

const KN_NEWPOINT_SAVEALL = 2

const KN_PARAM_HONORBNDS = 1002

const KN_HONORBNDS_AUTO = -1

const KN_HONORBNDS_NO = 0

const KN_HONORBNDS_ALWAYS = 1

const KN_HONORBNDS_INITPT = 2

const KN_PARAM_NLP_ALGORITHM = 1003

const KN_NLP_ALG_AUTOMATIC = 0

const KN_NLP_ALG_AUTO = 0

const KN_NLP_ALG_BAR_DIRECT = 1

const KN_NLP_ALG_BAR_CG = 2

const KN_NLP_ALG_ACT_CG = 3

const KN_NLP_ALG_ACT_SQP = 4

const KN_NLP_ALG_MULTI = 5

const KN_NLP_ALG_AL = 6

const KN_PARAM_ALGORITHM = 1003

const KN_PARAM_ALG = 1003

const KN_ALG_AUTOMATIC = 0

const KN_ALG_AUTO = 0

const KN_ALG_BAR_DIRECT = 1

const KN_ALG_BAR_CG = 2

const KN_ALG_ACT_CG = 3

const KN_ALG_ACT_SQP = 4

const KN_ALG_MULTI = 5

const KN_ALG_AL = 6

const KN_PARAM_BAR_MURULE = 1004

const KN_BAR_MURULE_AUTOMATIC = 0

const KN_BAR_MURULE_AUTO = 0

const KN_BAR_MURULE_MONOTONE = 1

const KN_BAR_MURULE_ADAPTIVE = 2

const KN_BAR_MURULE_PROBING = 3

const KN_BAR_MURULE_DAMPMPC = 4

const KN_BAR_MURULE_FULLMPC = 5

const KN_BAR_MURULE_QUALITY = 6

const KN_PARAM_BAR_FEASIBLE = 1006

const KN_BAR_FEASIBLE_NO = 0

const KN_BAR_FEASIBLE_STAY = 1

const KN_BAR_FEASIBLE_GET = 2

const KN_BAR_FEASIBLE_GET_STAY = 3

const KN_PARAM_GRADOPT = 1007

const KN_GRADOPT_EXACT = 1

const KN_GRADOPT_FORWARD = 2

const KN_GRADOPT_CENTRAL = 3

const KN_GRADOPT_USER_FORWARD = 4

const KN_GRADOPT_USER_CENTRAL = 5

const KN_PARAM_HESSOPT = 1008

const KN_HESSOPT_AUTO = 0

const KN_HESSOPT_EXACT = 1

const KN_HESSOPT_BFGS = 2

const KN_HESSOPT_SR1 = 3

const KN_HESSOPT_PRODUCT_FINDIFF = 4

const KN_HESSOPT_PRODUCT = 5

const KN_HESSOPT_LBFGS = 6

const KN_HESSOPT_GAUSS_NEWTON = 7

const KN_PARAM_BAR_INITPT = 1009

const KN_BAR_INITPT_AUTO = 0

const KN_BAR_INITPT_CONVEX = 1

const KN_BAR_INITPT_NEARBND = 2

const KN_BAR_INITPT_CENTRAL = 3

const KN_PARAM_ACT_LPSOLVER = 1012

const KN_ACT_LPSOLVER_INTERNAL = 1

const KN_ACT_LPSOLVER_CPLEX = 2

const KN_ACT_LPSOLVER_XPRESS = 3

const KN_PARAM_CG_MAXIT = 1013

const KN_PARAM_MAXIT = 1014

const KN_PARAM_OUTLEV = 1015

const KN_OUTLEV_NONE = 0

const KN_OUTLEV_SUMMARY = 1

const KN_OUTLEV_ITER_10 = 2

const KN_OUTLEV_ITER = 3

const KN_OUTLEV_ITER_VERBOSE = 4

const KN_OUTLEV_ITER_X = 5

const KN_OUTLEV_ALL = 6

const KN_PARAM_OUTMODE = 1016

const KN_OUTMODE_SCREEN = 0

const KN_OUTMODE_FILE = 1

const KN_OUTMODE_BOTH = 2

const KN_PARAM_SCALE = 1017

const KN_SCALE_NEVER = 0

const KN_SCALE_NO = 0

const KN_SCALE_USER_INTERNAL = 1

const KN_SCALE_USER_NONE = 2

const KN_SCALE_INTERNAL = 3

const KN_PARAM_SOC = 1019

const KN_SOC_NO = 0

const KN_SOC_MAYBE = 1

const KN_SOC_YES = 2

const KN_PARAM_DELTA = 1020

const KN_PARAM_BAR_FEASMODETOL = 1021

const KN_PARAM_FEASTOL = 1022

const KN_PARAM_FEASTOLABS = 1023

const KN_PARAM_MAXTIMECPU = 1024

const KN_PARAM_BAR_INITMU = 1025

const KN_PARAM_OBJRANGE = 1026

const KN_PARAM_OPTTOL = 1027

const KN_PARAM_OPTTOLABS = 1028

const KN_PARAM_LINSOLVER_PIVOTTOL = 1029

const KN_PARAM_XTOL = 1030

const KN_PARAM_DEBUG = 1031

const KN_DEBUG_NONE = 0

const KN_DEBUG_PROBLEM = 1

const KN_DEBUG_EXECUTION = 2

const KN_PARAM_MULTISTART = 1033

const KN_PARAM_MSENABLE = 1033

const KN_PARAM_MS_ENABLE = 1033

const KN_MULTISTART_NO = 0

const KN_MS_ENABLE_NO = 0

const KN_MULTISTART_YES = 1

const KN_MS_ENABLE_YES = 1

const KN_PARAM_MSMAXSOLVES = 1034

const KN_PARAM_MS_MAXSOLVES = 1034

const KN_PARAM_MSMAXBNDRANGE = 1035

const KN_PARAM_MS_MAXBNDRANGE = 1035

const KN_PARAM_MSMAXTIMECPU = 1036

const KN_PARAM_MS_MAXTIMECPU = 1036

const KN_PARAM_MSMAXTIMEREAL = 1037

const KN_PARAM_MS_MAXTIMEREAL = 1037

const KN_PARAM_LMSIZE = 1038

const KN_PARAM_BAR_MAXCROSSIT = 1039

const KN_PARAM_MAXTIMEREAL = 1040

const KN_PARAM_CG_PRECOND = 1041

const KN_CG_PRECOND_NONE = 0

const KN_CG_PRECOND_CHOL = 1

const KN_PARAM_BLASOPTION = 1042

const KN_BLASOPTION_AUTO = -1

const KN_BLASOPTION_KNITRO = 0

const KN_BLASOPTION_INTEL = 1

const KN_BLASOPTION_DYNAMIC = 2

const KN_BLASOPTION_BLIS = 3

const KN_BLASOPTION_APPLE = 4

const KN_PARAM_BAR_MAXREFACTOR = 1043

const KN_PARAM_LINESEARCH_MAXTRIALS = 1044

const KN_PARAM_BLASOPTIONLIB = 1045

const KN_PARAM_OUTAPPEND = 1046

const KN_OUTAPPEND_NO = 0

const KN_OUTAPPEND_YES = 1

const KN_PARAM_OUTDIR = 1047

const KN_PARAM_CPLEXLIB = 1048

const KN_PARAM_BAR_PENRULE = 1049

const KN_BAR_PENRULE_AUTO = 0

const KN_BAR_PENRULE_SINGLE = 1

const KN_BAR_PENRULE_FLEX = 2

const KN_PARAM_BAR_PENCONS = 1050

const KN_BAR_PENCONS_AUTO = -1

const KN_BAR_PENCONS_NONE = 0

const KN_BAR_PENCONS_ALL = 2

const KN_BAR_PENCONS_EQUALITIES = 3

const KN_BAR_PENCONS_INFEAS = 4

const KN_PARAM_MSNUMTOSAVE = 1051

const KN_PARAM_MS_NUMTOSAVE = 1051

const KN_PARAM_MSSAVETOL = 1052

const KN_PARAM_MS_SAVETOL = 1052

const KN_PARAM_PRESOLVEDEBUG = 1053

const KN_PRESOLVEDBG_NONE = 0

const KN_PRESOLVEDBG_BASIC = 1

const KN_PRESOLVEDBG_VERBOSE = 2

const KN_PRESOLVEDBG_DETAIL = 3

const KN_PARAM_MSTERMINATE = 1054

const KN_PARAM_MS_TERMINATE = 1054

const KN_MSTERMINATE_MAXSOLVES = 0

const KN_MS_TERMINATE_MAXSOLVES = 0

const KN_MSTERMINATE_OPTIMAL = 1

const KN_MS_TERMINATE_OPTIMAL = 1

const KN_MSTERMINATE_FEASIBLE = 2

const KN_MS_TERMINATE_FEASIBLE = 2

const KN_MSTERMINATE_ANY = 3

const KN_MS_TERMINATE_ANY = 3

const KN_MSTERMINATE_RULEBASED = 4

const KN_MS_TERMINATE_RULEBASED = 4

const KN_PARAM_MSSTARTPTRANGE = 1055

const KN_PARAM_MS_STARTPTRANGE = 1055

const KN_PARAM_INFEASTOL = 1056

const KN_PARAM_LINSOLVER = 1057

const KN_LINSOLVER_AUTO = 0

const KN_LINSOLVER_INTERNAL = 1

const KN_LINSOLVER_HYBRID = 2

const KN_LINSOLVER_DENSEQR = 3

const KN_LINSOLVER_MA27 = 4

const KN_LINSOLVER_MA57 = 5

const KN_LINSOLVER_MKLPARDISO = 6

const KN_LINSOLVER_MA97 = 7

const KN_LINSOLVER_MA86 = 8

const KN_LINSOLVER_APPLE = 9

const KN_PARAM_BAR_DIRECTINTERVAL = 1058

const KN_PARAM_PRESOLVE = 1059

const KN_PRESOLVE_NO = 0

const KN_PRESOLVE_NONE = 0

const KN_PRESOLVE_YES = 1

const KN_PRESOLVE_BASIC = 1

const KN_PRESOLVE_ADVANCED = 2

const KN_PARAM_PRESOLVE_TOL = 1060

const KN_PARAM_BAR_SWITCHRULE = 1061

const KN_BAR_SWITCHRULE_AUTO = -1

const KN_BAR_SWITCHRULE_NEVER = 0

const KN_BAR_SWITCHRULE_MODERATE = 2

const KN_BAR_SWITCHRULE_AGGRESSIVE = 3

const KN_PARAM_HESSIAN_NO_F = 1062

const KN_HESSIAN_NO_F_FORBID = 0

const KN_HESSIAN_NO_F_ALLOW = 1

const KN_PARAM_MA_TERMINATE = 1063

const KN_MA_TERMINATE_ALL = 0

const KN_MA_TERMINATE_OPTIMAL = 1

const KN_MA_TERMINATE_FEASIBLE = 2

const KN_MA_TERMINATE_ANY = 3

const KN_PARAM_MA_MAXTIMECPU = 1064

const KN_PARAM_MA_MAXTIMEREAL = 1065

const KN_PARAM_MSSEED = 1066

const KN_PARAM_MS_SEED = 1066

const KN_PARAM_MA_OUTSUB = 1067

const KN_MA_OUTSUB_NONE = 0

const KN_MA_OUTSUB_YES = 1

const KN_PARAM_MS_OUTSUB = 1068

const KN_MS_OUTSUB_NONE = 0

const KN_MS_OUTSUB_YES = 1

const KN_PARAM_XPRESSLIB = 1069

const KN_PARAM_TUNER = 1070

const KN_TUNER_OFF = 0

const KN_TUNER_ON = 1

const KN_PARAM_TUNER_OPTIONSFILE = 1071

const KN_PARAM_TUNER_MAXTIMECPU = 1072

const KN_PARAM_TUNER_MAXTIMEREAL = 1073

const KN_PARAM_TUNER_OUTSUB = 1074

const KN_TUNER_OUTSUB_NONE = 0

const KN_TUNER_OUTSUB_SUMMARY = 1

const KN_TUNER_OUTSUB_ALL = 2

const KN_PARAM_TUNER_TERMINATE = 1075

const KN_TUNER_TERMINATE_ALL = 0

const KN_TUNER_TERMINATE_OPTIMAL = 1

const KN_TUNER_TERMINATE_FEASIBLE = 2

const KN_TUNER_TERMINATE_ANY = 3

const KN_PARAM_LINSOLVER_OOC = 1076

const KN_LINSOLVER_OOC_NO = 0

const KN_LINSOLVER_OOC_MAYBE = 1

const KN_LINSOLVER_OOC_YES = 2

const KN_PARAM_BAR_RELAXCONS = 1077

const KN_BAR_RELAXCONS_NONE = 0

const KN_BAR_RELAXCONS_EQS = 1

const KN_BAR_RELAXCONS_INEQS = 2

const KN_BAR_RELAXCONS_ALL = 3

const KN_PARAM_MSDETERMINISTIC = 1078

const KN_PARAM_MS_DETERMINISTIC = 1078

const KN_MSDETERMINISTIC_NO = 0

const KN_MS_DETERMINISTIC_NO = 0

const KN_MSDETERMINISTIC_YES = 1

const KN_MS_DETERMINISTIC_YES = 1

const KN_PARAM_BAR_REFINEMENT = 1079

const KN_BAR_REFINEMENT_NO = 0

const KN_BAR_REFINEMENT_YES = 1

const KN_PARAM_DERIVCHECK = 1080

const KN_DERIVCHECK_NONE = 0

const KN_DERIVCHECK_FIRST = 1

const KN_DERIVCHECK_SECOND = 2

const KN_DERIVCHECK_ALL = 3

const KN_PARAM_DERIVCHECK_TYPE = 1081

const KN_DERIVCHECK_FORWARD = 1

const KN_DERIVCHECK_CENTRAL = 2

const KN_PARAM_DERIVCHECK_TOL = 1082

const KN_PARAM_LINSOLVER_INEXACT = 1083

const KN_LINSOLVER_INEXACT_NO = 0

const KN_LINSOLVER_INEXACT_YES = 1

const KN_PARAM_LINSOLVER_INEXACTTOL = 1084

const KN_PARAM_MAXFEVALS = 1085

const KN_PARAM_FSTOPVAL = 1086

const KN_PARAM_DATACHECK = 1087

const KN_DATACHECK_NO = 0

const KN_DATACHECK_YES = 1

const KN_PARAM_DERIVCHECK_TERMINATE = 1088

const KN_DERIVCHECK_STOPERROR = 1

const KN_DERIVCHECK_STOPALWAYS = 2

const KN_PARAM_BAR_WATCHDOG = 1089

const KN_BAR_WATCHDOG_NO = 0

const KN_BAR_WATCHDOG_YES = 1

const KN_PARAM_FTOL = 1090

const KN_PARAM_FTOL_ITERS = 1091

const KN_PARAM_ACT_QPALG = 1092

const KN_ACT_QPALG_AUTO = 0

const KN_ACT_QPALG_BAR_DIRECT = 1

const KN_ACT_QPALG_BAR_CG = 2

const KN_ACT_QPALG_ACT_CG = 3

const KN_PARAM_BAR_INITPI_MPEC = 1093

const KN_PARAM_XTOL_ITERS = 1094

const KN_PARAM_LINESEARCH = 1095

const KN_LINESEARCH_AUTO = 0

const KN_LINESEARCH_BACKTRACK = 1

const KN_LINESEARCH_INTERPOLATE = 2

const KN_LINESEARCH_WEAKWOLFE = 3

const KN_PARAM_OUT_CSVINFO = 1096

const KN_OUT_CSVINFO_NO = 0

const KN_OUT_CSVINFO_YES = 1

const KN_PARAM_INITPENALTY = 1097

const KN_PARAM_ACT_LPFEASTOL = 1098

const KN_PARAM_CG_STOPTOL = 1099

const KN_PARAM_RESTARTS = 1100

const KN_PARAM_RESTARTS_MAXIT = 1101

const KN_PARAM_BAR_SLACKBOUNDPUSH = 1102

const KN_PARAM_CG_PMEM = 1103

const KN_PARAM_BAR_SWITCHOBJ = 1104

const KN_BAR_SWITCHOBJ_NONE = 0

const KN_BAR_SWITCHOBJ_SCALARPROX = 1

const KN_BAR_SWITCHOBJ_DIAGPROX = 2

const KN_PARAM_OUTNAME = 1105

const KN_PARAM_OUT_CSVNAME = 1106

const KN_PARAM_ACT_PARAMETRIC = 1107

const KN_ACT_PARAMETRIC_NO = 0

const KN_ACT_PARAMETRIC_MAYBE = 1

const KN_ACT_PARAMETRIC_YES = 2

const KN_PARAM_ACT_LPDUMPMPS = 1108

const KN_ACT_LPDUMPMPS_NO = 0

const KN_ACT_LPDUMPMPS_YES = 1

const KN_PARAM_ACT_LPALG = 1109

const KN_ACT_LPALG_DEFAULT = 0

const KN_ACT_LPALG_PRIMAL = 1

const KN_ACT_LPALG_PRIMALSIMPLEX = 1

const KN_ACT_LPALG_DUAL = 2

const KN_ACT_LPALG_DUALSIMPLEX = 2

const KN_ACT_LPALG_BARRIER = 3

const KN_PARAM_ACT_LPPRESOLVE = 1110

const KN_ACT_LPPRESOLVE_OFF = 0

const KN_ACT_LPPRESOLVE_ON = 1

const KN_PARAM_ACT_LPPENALTY = 1111

const KN_ACT_LPPENALTY_ALL = 1

const KN_ACT_LPPENALTY_NONLINEAR = 2

const KN_ACT_LPPENALTY_DYNAMIC = 3

const KN_PARAM_BNDRANGE = 1112

const KN_PARAM_BAR_CONIC_ENABLE = 1113

const KN_BAR_CONIC_ENABLE_AUTO = -1

const KN_BAR_CONIC_ENABLE_NONE = 0

const KN_BAR_CONIC_ENABLE_SOC = 1

const KN_PARAM_CONVEX = 1114

const KN_CONVEX_AUTO = -1

const KN_CONVEX_NO = 0

const KN_CONVEX_YES = 1

const KN_PARAM_OUT_HINTS = 1115

const KN_OUT_HINTS_NO = 0

const KN_OUT_HINTS_YES = 1

const KN_PARAM_EVAL_FCGA = 1116

const KN_EVAL_FCGA_NO = 0

const KN_EVAL_FCGA_YES = 1

const KN_PARAM_BAR_MAXCORRECTORS = 1117

const KN_PARAM_STRAT_WARM_START = 1118

const KN_STRAT_WARM_START_NO = 0

const KN_STRAT_WARM_START_YES = 1

const KN_PARAM_FINDIFF_TERMINATE = 1119

const KN_FINDIFF_TERMINATE_NONE = 0

const KN_FINDIFF_TERMINATE_ERREST = 1

const KN_PARAM_CPUPLATFORM = 1120

const KN_CPUPLATFORM_AUTO = -1

const KN_CPUPLATFORM_COMPATIBLE = 1

const KN_CPUPLATFORM_SSE2 = 2

const KN_CPUPLATFORM_AVX = 3

const KN_CPUPLATFORM_AVX2 = 4

const KN_CPUPLATFORM_AVX512 = 5

const KN_PARAM_PRESOLVE_PASSES = 1121

const KN_PARAM_PRESOLVE_LEVEL = 1122

const KN_PRESOLVE_LEVEL_AUTO = -1

const KN_PRESOLVE_LEVEL_1 = 1

const KN_PRESOLVE_LEVEL_2 = 2

const KN_PARAM_FINDIFF_RELSTEPSIZE = 1123

const KN_PARAM_INFEASTOL_ITERS = 1124

const KN_PARAM_PRESOLVEOP_TIGHTEN = 1125

const KN_PRESOLVEOP_TIGHTEN_AUTO = -1

const KN_PRESOLVEOP_TIGHTEN_NONE = 0

const KN_PRESOLVEOP_TIGHTEN_VARBND = 1

const KN_PRESOLVEOP_TIGHTEN_COEF = 2

const KN_PRESOLVEOP_TIGHTEN_ALL = 3

const KN_PARAM_BAR_LINSYS = 1126

const KN_BAR_LINSYS_AUTO = -1

const KN_BAR_LINSYS_FULL = 0

const KN_BAR_LINSYS_COMPACT1 = 1

const KN_BAR_LINSYS_ELIMINATE_SLACKS = 1

const KN_BAR_LINSYS_COMPACT2 = 2

const KN_BAR_LINSYS_ELIMINATE_BOUNDS = 2

const KN_BAR_LINSYS_ELIMINATE_INEQS = 3

const KN_PARAM_PRESOLVE_INITPT = 1127

const KN_PRESOLVE_INITPT_AUTO = -1

const KN_PRESOLVE_INITPT_NOSHIFT = 0

const KN_PRESOLVE_INITPT_LINSHIFT = 1

const KN_PRESOLVE_INITPT_ANYSHIFT = 2

const KN_PARAM_ACT_QPPENALTY = 1128

const KN_ACT_QPPENALTY_AUTO = -1

const KN_ACT_QPPENALTY_NONE = 0

const KN_ACT_QPPENALTY_ALL = 1

const KN_PARAM_BAR_LINSYS_STORAGE = 1129

const KN_BAR_LINSYS_STORAGE_AUTO = -1

const KN_BAR_LINSYS_STORAGE_LOWMEM = 1

const KN_BAR_LINSYS_STORAGE_NORMAL = 2

const KN_PARAM_LINSOLVER_MAXITREF = 1130

const KN_PARAM_BFGS_SCALING = 1131

const KN_BFGS_SCALING_DYNAMIC = 0

const KN_BFGS_SCALING_INVHESS = 1

const KN_BFGS_SCALING_HESS = 2

const KN_PARAM_BAR_INITSHIFTTOL = 1132

const KN_PARAM_NUMTHREADS = 1133

const KN_PARAM_CONCURRENT_EVALS = 1134

const KN_CONCURRENT_EVALS_NO = 0

const KN_CONCURRENT_EVALS_YES = 1

const KN_PARAM_BLAS_NUMTHREADS = 1135

const KN_PARAM_LINSOLVER_NUMTHREADS = 1136

const KN_PARAM_MS_NUMTHREADS = 1137

const KN_PARAM_CONIC_NUMTHREADS = 1138

const KN_PARAM_NCVX_QCQP_INIT = 1139

const KN_NCVX_QCQP_INIT_AUTO = -1

const KN_NCVX_QCQP_INIT_NONE = 0

const KN_NCVX_QCQP_INIT_LINEAR = 1

const KN_NCVX_QCQP_INIT_HYBRID = 2

const KN_NCVX_QCQP_INIT_PENALTY = 3

const KN_NCVX_QCQP_INIT_CVXQUAD = 4

const KN_PARAM_FINDIFF_ESTNOISE = 1140

const KN_FINDIFF_ESTNOISE_NO = 0

const KN_FINDIFF_ESTNOISE_YES = 1

const KN_FINDIFF_ESTNOISE_WITHCURV = 2

const KN_PARAM_FINDIFF_NUMTHREADS = 1141

const KN_PARAM_BAR_MPEC_HEURISTIC = 1142

const KN_BAR_MPEC_HEURISTIC_NO = 0

const KN_BAR_MPEC_HEURISTIC_YES = 1

const KN_PARAM_PRESOLVEOP_REDUNDANT = 1143

const KN_PRESOLVEOP_REDUNDANT_NONE = 0

const KN_PRESOLVEOP_REDUNDANT_DUPCON = 1

const KN_PRESOLVEOP_REDUNDANT_DEPCON = 2

const KN_PARAM_LINSOLVER_ORDERING = 1144

const KN_LINSOLVER_ORDERING_AUTO = -1

const KN_LINSOLVER_ORDERING_BEST = 0

const KN_LINSOLVER_ORDERING_AMD = 1

const KN_LINSOLVER_ORDERING_METIS = 2

const KN_PARAM_LINSOLVER_NODEAMALG = 1145

const KN_PARAM_PRESOLVEOP_SUBSTITUTION = 1146

const KN_PRESOLVEOP_SUBSTITUTION_AUTO = -1

const KN_PRESOLVEOP_SUBSTITUTION_NONE = 0

const KN_PRESOLVEOP_SUBSTITUTION_SIMPLE = 1

const KN_PRESOLVEOP_SUBSTITUTION_ALL = 2

const KN_PARAM_PRESOLVEOP_SUBSTITUTION_TOL = 1147

const KN_PARAM_MS_INITPT_CLUSTER = 1149

const KN_MS_INITPT_CLUSTER_NONE = 0

const KN_MS_INITPT_CLUSTER_SL = 1

const KN_PARAM_SCALE_VARS = 1153

const KN_SCALE_VARS_NONE = 0

const KN_SCALE_VARS_BNDS = 1

const KN_PARAM_BAR_MAXMU = 1154

const KN_PARAM_BAR_GLOBALIZE = 1155

const KN_BAR_GLOBALIZE_NONE = 0

const KN_BAR_GLOBALIZE_KKT = 1

const KN_BAR_GLOBALIZE_FILTER = 2

const KN_PARAM_LINSOLVER_SCALING = 1156

const KN_LINSOLVER_SCALING_NONE = 0

const KN_LINSOLVER_SCALING_ALWAYS = 1

const KN_LINSOLVER_SCALING_DYNAMIC = 2

const KN_PARAM_INITPT_STRATEGY = 1158

const KN_INITPT_STRATEGY_AUTO = -1

const KN_INITPT_STRATEGY_BASIC = 1

const KN_INITPT_STRATEGY_ADVANCED = 2

const KN_PARAM_EVAL_COST = 1159

const KN_EVAL_COST_UNSPECIFIED = 0

const KN_EVAL_COST_INEXPENSIVE = 1

const KN_EVAL_COST_EXPENSIVE = 2

const KN_PARAM_MS_TERMINATERULE_TOL = 1160

const KN_PARAM_SOLTYPE = 1161

const KN_SOLTYPE_FINAL = 0

const KN_SOLTYPE_BESTFEAS = 1

const KN_PARAM_MAXTIME = 1163

const KN_PARAM_MA_SUB_MAXTIME = 1164

const KN_PARAM_MS_SUB_MAXTIME = 1165

const KN_PARAM_TUNER_SUB_MAXTIME = 1166

const KN_PARAM_INITPTFILE = 1167

const KN_PARAM_LP_ALGORITHM = 1170

const KN_PARAM_LP_ALG = 1170

const KN_LP_ALG_AUTO = -1

const KN_LP_ALG_NLPALGORITHM = 0

const KN_LP_ALG_PRIMALSIMPLEX = 1

const KN_LP_ALG_DUALSIMPLEX = 2

const KN_LP_ALG_BARRIER = 3

const KN_LP_ALG_PDLP = 4

const KN_PARAM_AL_INITPENALTY = 1171

const KN_PARAM_AL_MAXPENALTY = 1172

const KN_PARAM_PRESOLVEOP_PROBING = 1174

const KN_PRESOLVEOP_PROBING_AUTO = -1

const KN_PRESOLVEOP_PROBING_OFF = 0

const KN_PRESOLVEOP_PROBING_LIGHT = 1

const KN_PRESOLVEOP_PROBING_FULL = 2

const KN_PARAM_PRESOLVEOP_CLIQUE_MERGING = 1176

const KN_PRESOLVEOP_CLIQUE_MERGING_AUTO = -1

const KN_PRESOLVEOP_CLIQUE_MERGING_OFF = 0

const KN_PRESOLVEOP_CLIQUE_MERGING_ON = 1

const KN_PARAM_MIP_METHOD = 2001

const KN_MIP_METHOD_AUTO = 0

const KN_MIP_METHOD_BB = 1

const KN_MIP_METHOD_HQG = 2

const KN_MIP_METHOD_MISQP = 3

const KN_PARAM_MIP_BRANCHRULE = 2002

const KN_MIP_BRANCH_AUTO = 0

const KN_MIP_BRANCH_MOSTFRAC = 1

const KN_MIP_BRANCH_PSEUDOCOST = 2

const KN_MIP_BRANCH_STRONG = 3

const KN_PARAM_MIP_SELECTRULE = 2003

const KN_MIP_SEL_AUTO = 0

const KN_MIP_SEL_DEPTHFIRST = 1

const KN_MIP_SEL_BESTBOUND = 2

const KN_MIP_SEL_COMBO_1 = 3

const KN_PARAM_MIP_INTGAPABS = 2004

const KN_PARAM_MIP_OPTGAPABS = 2004

const KN_PARAM_MIP_INTGAPREL = 2005

const KN_PARAM_MIP_OPTGAPREL = 2005

const KN_PARAM_MIP_MAXTIMECPU = 2006

const KN_PARAM_MIP_MAXTIMEREAL = 2007

const KN_PARAM_MIP_MAXSOLVES = 2008

const KN_PARAM_MIP_INTEGERTOL = 2009

const KN_PARAM_MIP_OUTLEVEL = 2010

const KN_MIP_OUTLEVEL_NONE = 0

const KN_MIP_OUTLEVEL_ITERS = 1

const KN_MIP_OUTLEVEL_ITERSTIME = 2

const KN_MIP_OUTLEVEL_ROOT = 3

const KN_PARAM_MIP_OUTINTERVAL = 2011

const KN_PARAM_MIP_OUTSUB = 2012

const KN_MIP_OUTSUB_NONE = 0

const KN_MIP_OUTSUB_YES = 1

const KN_MIP_OUTSUB_YESPROB = 2

const KN_PARAM_MIP_DEBUG = 2013

const KN_MIP_DEBUG_NONE = 0

const KN_MIP_DEBUG_ALL = 1

const KN_PARAM_MIP_IMPLICATNS = 2014

const KN_PARAM_MIP_IMPLICATIONS = 2014

const KN_MIP_IMPLICATNS_NO = 0

const KN_MIP_IMPLICATIONS_NO = 0

const KN_MIP_IMPLICATNS_YES = 1

const KN_MIP_IMPLICATIONS_YES = 1

const KN_PARAM_MIP_GUB_BRANCH = 2015

const KN_MIP_GUB_BRANCH_NO = 0

const KN_MIP_GUB_BRANCH_YES = 1

const KN_PARAM_MIP_KNAPSACK = 2016

const KN_MIP_KNAPSACK_AUTO = -1

const KN_MIP_KNAPSACK_NO = 0

const KN_MIP_KNAPSACK_NONE = 0

const KN_MIP_KNAPSACK_ROOT = 1

const KN_MIP_KNAPSACK_TREE = 2

const KN_MIP_KNAPSACK_INEQ = 1

const KN_MIP_KNAPSACK_LIFTED = 2

const KN_MIP_KNAPSACK_ALL = 3

const KN_PARAM_MIP_ROUNDING = 2017

const KN_MIP_ROUND_AUTO = -1

const KN_MIP_ROUND_NONE = 0

const KN_MIP_ROUND_HEURISTIC = 2

const KN_MIP_ROUND_NLP_SOME = 3

const KN_MIP_ROUND_NLP_ALWAYS = 4

const KN_PARAM_MIP_ROOT_NLPALG = 2018

const KN_PARAM_MIP_ROOTALG = 2018

const KN_MIP_ROOT_NLPALG_AUTO = 0

const KN_MIP_ROOTALG_AUTO = 0

const KN_MIP_ROOT_NLPALG_BAR_DIRECT = 1

const KN_MIP_ROOTALG_BAR_DIRECT = 1

const KN_MIP_ROOT_NLPALG_BAR_CG = 2

const KN_MIP_ROOTALG_BAR_CG = 2

const KN_MIP_ROOT_NLPALG_ACT_CG = 3

const KN_MIP_ROOTALG_ACT_CG = 3

const KN_MIP_ROOT_NLPALG_ACT_SQP = 4

const KN_MIP_ROOTALG_ACT_SQP = 4

const KN_MIP_ROOTALG_MULTI = 5

const KN_PARAM_MIP_LPALG = 2019

const KN_MIP_LPALG_AUTO = 0

const KN_MIP_LPALG_BAR_DIRECT = 1

const KN_MIP_LPALG_BAR_CG = 2

const KN_MIP_LPALG_ACT_CG = 3

const KN_PARAM_MIP_TERMINATE = 2020

const KN_MIP_TERMINATE_OPTIMAL = 0

const KN_MIP_TERMINATE_FEASIBLE = 1

const KN_PARAM_MIP_MAXNODES = 2021

const KN_PARAM_MIP_HEURISTIC = 2022

const KN_MIP_HEURISTIC_AUTO = -1

const KN_MIP_HEURISTIC_NONE = 0

const KN_MIP_HEURISTIC_FEASPUMP = 2

const KN_MIP_HEURISTIC_MPEC = 3

const KN_MIP_HEURISTIC_DIVING = 4

const KN_PARAM_MIP_HEUR_MAXIT = 2023

const KN_PARAM_MIP_HEUR_MAXTIMECPU = 2024

const KN_PARAM_MIP_HEUR_MAXTIMEREAL = 2025

const KN_PARAM_MIP_PSEUDOINIT = 2026

const KN_MIP_PSEUDOINIT_AUTO = 0

const KN_MIP_PSEUDOINIT_AVE = 1

const KN_MIP_PSEUDOINIT_STRONG = 2

const KN_PARAM_MIP_STRONG_MAXIT = 2027

const KN_PARAM_MIP_STRONG_CANDLIM = 2028

const KN_PARAM_MIP_STRONG_LEVEL = 2029

const KN_PARAM_MIP_INTVAR_STRATEGY = 2030

const KN_MIP_INTVAR_STRATEGY_NONE = 0

const KN_MIP_INTVAR_STRATEGY_RELAX = 1

const KN_MIP_INTVAR_STRATEGY_MPEC = 2

const KN_PARAM_MIP_RELAXABLE = 2031

const KN_MIP_RELAXABLE_NONE = 0

const KN_MIP_RELAXABLE_ALL = 1

const KN_PARAM_MIP_NODE_NLPALG = 2032

const KN_PARAM_MIP_NODEALG = 2032

const KN_MIP_NODE_NLPALG_AUTO = 0

const KN_MIP_NODEALG_AUTO = 0

const KN_MIP_NODE_NLPALG_BAR_DIRECT = 1

const KN_MIP_NODEALG_BAR_DIRECT = 1

const KN_MIP_NODE_NLPALG_BAR_CG = 2

const KN_MIP_NODEALG_BAR_CG = 2

const KN_MIP_NODE_NLPALG_ACT_CG = 3

const KN_MIP_NODEALG_ACT_CG = 3

const KN_MIP_NODE_NLPALG_ACT_SQP = 4

const KN_MIP_NODEALG_ACT_SQP = 4

const KN_MIP_NODEALG_MULTI = 5

const KN_PARAM_MIP_HEUR_TERMINATE = 2033

const KN_MIP_HEUR_TERMINATE_FEASIBLE = 1

const KN_MIP_HEUR_TERMINATE_LIMIT = 2

const KN_PARAM_MIP_SELECTDIR = 2034

const KN_MIP_SELECTDIR_DOWN = 0

const KN_MIP_SELECTDIR_UP = 1

const KN_PARAM_MIP_CUTFACTOR = 2035

const KN_PARAM_MIP_ZEROHALF = 2036

const KN_MIP_ZEROHALF_AUTO = -1

const KN_MIP_ZEROHALF_NONE = 0

const KN_MIP_ZEROHALF_ROOT = 1

const KN_MIP_ZEROHALF_TREE = 2

const KN_MIP_ZEROHALF_ALL = 3

const KN_PARAM_MIP_MIR = 2037

const KN_MIP_MIR_AUTO = -1

const KN_MIP_MIR_NONE = 0

const KN_MIP_MIR_ROOT = 1

const KN_MIP_MIR_TREE = 2

const KN_MIP_MIR_NLP = 2

const KN_PARAM_MIP_CLIQUE = 2038

const KN_MIP_CLIQUE_AUTO = -1

const KN_MIP_CLIQUE_NONE = 0

const KN_MIP_CLIQUE_ROOT = 1

const KN_MIP_CLIQUE_TREE = 2

const KN_MIP_CLIQUE_ALL = 3

const KN_PARAM_MIP_HEUR_STRATEGY = 2039

const KN_MIP_HEUR_STRATEGY_AUTO = -1

const KN_MIP_HEUR_STRATEGY_NONE = 0

const KN_MIP_HEUR_STRATEGY_BASIC = 1

const KN_MIP_HEUR_STRATEGY_ADVANCED = 2

const KN_MIP_HEUR_STRATEGY_EXTENSIVE = 3

const KN_PARAM_MIP_HEUR_FEASPUMP = 2040

const KN_MIP_HEUR_FEASPUMP_AUTO = -1

const KN_MIP_HEUR_FEASPUMP_OFF = 0

const KN_MIP_HEUR_FEASPUMP_ON = 1

const KN_PARAM_MIP_HEUR_MPEC = 2041

const KN_MIP_HEUR_MPEC_AUTO = -1

const KN_MIP_HEUR_MPEC_OFF = 0

const KN_MIP_HEUR_MPEC_ON = 1

const KN_PARAM_MIP_HEUR_DIVING = 2042

const KN_PARAM_MIP_CUTTINGPLANE = 2043

const KN_MIP_CUTTINGPLANE_NONE = 0

const KN_MIP_CUTTINGPLANE_ROOT = 1

const KN_PARAM_MIP_CUTOFF = 2044

const KN_PARAM_MIP_HEUR_LNS = 2045

const KN_PARAM_MIP_MULTISTART = 2046

const KN_MIP_MULTISTART_OFF = 0

const KN_MIP_MULTISTART_ON = 1

const KN_PARAM_MIP_LIFTPROJECT = 2047

const KN_MIP_LIFTPROJECT_AUTO = -1

const KN_MIP_LIFTPROJECT_NONE = 0

const KN_MIP_LIFTPROJECT_ROOT = 1

const KN_PARAM_MIP_NUMTHREADS = 2048

const KN_PARAM_MIP_HEUR_MISQP = 2049

const KN_MIP_HEUR_MISQP_AUTO = -1

const KN_MIP_HEUR_MISQP_OFF = 0

const KN_MIP_HEUR_MISQP_ON = 1

const KN_PARAM_MIP_RESTART = 2050

const KN_MIP_RESTART_OFF = 0

const KN_MIP_RESTART_ON = 1

const KN_PARAM_MIP_GOMORY = 2051

const KN_MIP_GOMORY_AUTO = -1

const KN_MIP_GOMORY_NONE = 0

const KN_MIP_GOMORY_ROOT = 1

const KN_MIP_GOMORY_TREE = 2

const KN_PARAM_MIP_CUT_PROBING = 2052

const KN_MIP_CUT_PROBING_AUTO = -1

const KN_MIP_CUT_PROBING_NONE = 0

const KN_MIP_CUT_PROBING_ROOT = 1

const KN_MIP_CUT_PROBING_TREE = 2

const KN_PARAM_MIP_CUT_FLOWCOVER = 2053

const KN_MIP_CUT_FLOWCOVER_AUTO = -1

const KN_MIP_CUT_FLOWCOVER_NONE = 0

const KN_MIP_CUT_FLOWCOVER_ROOT = 1

const KN_MIP_CUT_FLOWCOVER_TREE = 2

const KN_PARAM_MIP_HEUR_LOCALSEARCH = 2054

const KN_MIP_HEUR_LOCALSEARCH_AUTO = -1

const KN_MIP_HEUR_LOCALSEARCH_OFF = 0

const KN_MIP_HEUR_LOCALSEARCH_ON = 1

const KN_PARAM_MIP_SUB_MAXTIME = 2055

const KN_PARAM_MIP_INITPTFILE = 2056

const KN_PARAM_MIP_ROOT_LPALG = 2057

const KN_MIP_ROOT_LPALG_AUTO = -1

const KN_MIP_ROOT_LPALG_NLPALGORITHM = 0

const KN_MIP_ROOT_LPALG_PRIMALSIMPLEX = 1

const KN_MIP_ROOT_LPALG_DUALSIMPLEX = 2

const KN_MIP_ROOT_LPALG_BARRIER = 3

const KN_MIP_ROOT_LPALG_PDLP = 4

const KN_PARAM_MIP_NODE_LPALG = 2058

const KN_MIP_NODE_LPALG_AUTO = -1

const KN_MIP_NODE_LPALG_NLPALGORITHM = 0

const KN_MIP_NODE_LPALG_PRIMALSIMPLEX = 1

const KN_MIP_NODE_LPALG_DUALSIMPLEX = 2

const KN_MIP_NODE_LPALG_BARRIER = 3

const KN_MIP_NODE_LPALG_PDLP = 4

const KN_PARAM_MIP_CUTOFFABS = 2059

const KN_PARAM_MIP_CUTOFFREL = 2060

const KN_PARAM_MIP_HEUR_FIXPROPAGATE = 2061

const KN_MIP_HEUR_FIXPROPAGATE_AUTO = -1

const KN_MIP_HEUR_FIXPROPAGATE_OFF = 0

const KN_MIP_HEUR_FIXPROPAGATE_ON = 1

const KN_PARAM_PAR_NUMTHREADS = 3001

const KN_PARAM_PAR_CONCURRENT_EVALS = 3002

const KN_PAR_CONCURRENT_EVALS_NO = 0

const KN_PAR_CONCURRENT_EVALS_YES = 1

const KN_PARAM_PAR_BLASNUMTHREADS = 3003

const KN_PARAM_PAR_LSNUMTHREADS = 3004

const KN_PARAM_PAR_MSNUMTHREADS = 3005

const KN_PAR_MSNUMTHREADS_AUTO = 0

const KN_PARAM_PAR_CONICNUMTHREADS = 3006
