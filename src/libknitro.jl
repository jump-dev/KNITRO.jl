#!format:off

const DBL_MAX = Float64(0x1.fffffffffffffp+1023)


const KNINT = Cint

const KNLONG = Clonglong

const KNBOOL = KNINT

const KN_context = Cvoid

const KN_context_ptr = Ptr{KN_context}

const LM_context = Cvoid

const LM_context_ptr = Ptr{LM_context}

function KN_get_release(length, release)
    ccall((:KN_get_release, libknitro), Cint, (Cint, Ptr{Cchar}), length, release)
end

function KN_new(kc)
    ccall((:KN_new, libknitro), Cint, (Ptr{KN_context_ptr},), kc)
end

function KN_free(kc)
    ccall((:KN_free, libknitro), Cint, (Ptr{KN_context_ptr},), kc)
end

function KN_checkout_license(lmc)
    ccall((:KN_checkout_license, libknitro), Cint, (Ptr{LM_context_ptr},), lmc)
end

function KN_new_lm(lmc, kc)
    ccall((:KN_new_lm, libknitro), Cint, (LM_context_ptr, Ptr{KN_context_ptr}), lmc, kc)
end

function KN_release_license(lmc)
    ccall((:KN_release_license, libknitro), Cint, (Ptr{LM_context_ptr},), lmc)
end

function KN_reset_params_to_defaults(kc)
    ccall((:KN_reset_params_to_defaults, libknitro), Cint, (KN_context_ptr,), kc)
end

function KN_load_param_file(kc, filename)
    ccall((:KN_load_param_file, libknitro), Cint, (KN_context_ptr, Ptr{Cchar}), kc, filename)
end

function KN_load_tuner_file(kc, filename)
    ccall((:KN_load_tuner_file, libknitro), Cint, (KN_context_ptr, Ptr{Cchar}), kc, filename)
end

function KN_save_param_file(kc, filename)
    ccall((:KN_save_param_file, libknitro), Cint, (KN_context_ptr, Ptr{Cchar}), kc, filename)
end

function KN_set_int_param_by_name(kc, name, value)
    ccall((:KN_set_int_param_by_name, libknitro), Cint, (KN_context_ptr, Ptr{Cchar}, Cint), kc, name, value)
end

function KN_set_char_param_by_name(kc, name, value)
    ccall((:KN_set_char_param_by_name, libknitro), Cint, (KN_context_ptr, Ptr{Cchar}, Ptr{Cchar}), kc, name, value)
end

function KN_set_double_param_by_name(kc, name, value)
    ccall((:KN_set_double_param_by_name, libknitro), Cint, (KN_context_ptr, Ptr{Cchar}, Cdouble), kc, name, value)
end

function KN_set_param_by_name(kc, name, value)
    ccall((:KN_set_param_by_name, libknitro), Cint, (KN_context_ptr, Ptr{Cchar}, Cdouble), kc, name, value)
end

function KN_set_int_param(kc, param_id, value)
    ccall((:KN_set_int_param, libknitro), Cint, (KN_context_ptr, Cint, Cint), kc, param_id, value)
end

function KN_set_char_param(kc, param_id, value)
    ccall((:KN_set_char_param, libknitro), Cint, (KN_context_ptr, Cint, Ptr{Cchar}), kc, param_id, value)
end

function KN_set_double_param(kc, param_id, value)
    ccall((:KN_set_double_param, libknitro), Cint, (KN_context_ptr, Cint, Cdouble), kc, param_id, value)
end

function KN_get_int_param_by_name(kc, name, value)
    ccall((:KN_get_int_param_by_name, libknitro), Cint, (KN_context_ptr, Ptr{Cchar}, Ptr{Cint}), kc, name, value)
end

function KN_get_double_param_by_name(kc, name, value)
    ccall((:KN_get_double_param_by_name, libknitro), Cint, (KN_context_ptr, Ptr{Cchar}, Ptr{Cdouble}), kc, name, value)
end

function KN_get_int_param(kc, param_id, value)
    ccall((:KN_get_int_param, libknitro), Cint, (KN_context_ptr, Cint, Ptr{Cint}), kc, param_id, value)
end

function KN_get_double_param(kc, param_id, value)
    ccall((:KN_get_double_param, libknitro), Cint, (KN_context_ptr, Cint, Ptr{Cdouble}), kc, param_id, value)
end

function KN_get_param_name(kc, param_id, param_name, output_size)
    ccall((:KN_get_param_name, libknitro), Cint, (KN_context_ptr, Cint, Ptr{Cchar}, Csize_t), kc, param_id, param_name, output_size)
end

function KN_get_param_doc(kc, param_id, description, output_size)
    ccall((:KN_get_param_doc, libknitro), Cint, (KN_context_ptr, Cint, Ptr{Cchar}, Csize_t), kc, param_id, description, output_size)
end

function KN_get_param_type(kc, param_id, param_type)
    ccall((:KN_get_param_type, libknitro), Cint, (KN_context_ptr, Cint, Ptr{Cint}), kc, param_id, param_type)
end

function KN_get_num_param_values(kc, param_id, num_param_values)
    ccall((:KN_get_num_param_values, libknitro), Cint, (KN_context_ptr, Cint, Ptr{Cint}), kc, param_id, num_param_values)
end

function KN_get_param_value_doc(kc, param_id, value_id, param_value_string, output_size)
    ccall((:KN_get_param_value_doc, libknitro), Cint, (KN_context_ptr, Cint, Cint, Ptr{Cchar}, Csize_t), kc, param_id, value_id, param_value_string, output_size)
end

function KN_get_param_id(kc, name, param_id)
    ccall((:KN_get_param_id, libknitro), Cint, (KN_context_ptr, Ptr{Cchar}, Ptr{Cint}), kc, name, param_id)
end

function KN_add_vars(kc, nV, indexVars)
    ccall((:KN_add_vars, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}), kc, nV, indexVars)
end

function KN_add_var(kc, indexVar)
    ccall((:KN_add_var, libknitro), Cint, (KN_context_ptr, Ptr{KNINT}), kc, indexVar)
end

function KN_add_cons(kc, nC, indexCons)
    ccall((:KN_add_cons, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}), kc, nC, indexCons)
end

function KN_add_con(kc, indexCon)
    ccall((:KN_add_con, libknitro), Cint, (KN_context_ptr, Ptr{KNINT}), kc, indexCon)
end

function KN_add_rsds(kc, nR, indexRsds)
    ccall((:KN_add_rsds, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}), kc, nR, indexRsds)
end

function KN_add_rsd(kc, indexRsd)
    ccall((:KN_add_rsd, libknitro), Cint, (KN_context_ptr, Ptr{KNINT}), kc, indexRsd)
end

function KN_set_var_lobnds(kc, nV, indexVars, xLoBnds)
    ccall((:KN_set_var_lobnds, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nV, indexVars, xLoBnds)
end

function KN_set_var_lobnds_all(kc, xLoBnds)
    ccall((:KN_set_var_lobnds_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, xLoBnds)
end

function KN_set_var_lobnd(kc, indexVar, xLoBnd)
    ccall((:KN_set_var_lobnd, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexVar, xLoBnd)
end

function KN_set_var_upbnds(kc, nV, indexVars, xUpBnds)
    ccall((:KN_set_var_upbnds, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nV, indexVars, xUpBnds)
end

function KN_set_var_upbnds_all(kc, xUpBnds)
    ccall((:KN_set_var_upbnds_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, xUpBnds)
end

function KN_set_var_upbnd(kc, indexVar, xUpBnd)
    ccall((:KN_set_var_upbnd, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexVar, xUpBnd)
end

function KN_set_var_fxbnds(kc, nV, indexVars, xFxBnds)
    ccall((:KN_set_var_fxbnds, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nV, indexVars, xFxBnds)
end

function KN_set_var_fxbnds_all(kc, xFxBnds)
    ccall((:KN_set_var_fxbnds_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, xFxBnds)
end

function KN_set_var_fxbnd(kc, indexVar, xFxBnd)
    ccall((:KN_set_var_fxbnd, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexVar, xFxBnd)
end

function KN_get_var_lobnds(kc, nV, indexVars, xLoBnds)
    ccall((:KN_get_var_lobnds, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nV, indexVars, xLoBnds)
end

function KN_get_var_lobnds_all(kc, xLoBnds)
    ccall((:KN_get_var_lobnds_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, xLoBnds)
end

function KN_get_var_lobnd(kc, indexVar, xLoBnd)
    ccall((:KN_get_var_lobnd, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cdouble}), kc, indexVar, xLoBnd)
end

function KN_get_var_upbnds(kc, nV, indexVars, xUpBnds)
    ccall((:KN_get_var_upbnds, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nV, indexVars, xUpBnds)
end

function KN_get_var_upbnds_all(kc, xUpBnds)
    ccall((:KN_get_var_upbnds_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, xUpBnds)
end

function KN_get_var_upbnd(kc, indexVar, xUpBnd)
    ccall((:KN_get_var_upbnd, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cdouble}), kc, indexVar, xUpBnd)
end

function KN_get_var_fxbnds(kc, nV, indexVars, xFxBnds)
    ccall((:KN_get_var_fxbnds, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nV, indexVars, xFxBnds)
end

function KN_get_var_fxbnds_all(kc, xFxBnds)
    ccall((:KN_get_var_fxbnds_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, xFxBnds)
end

function KN_get_var_fxbnd(kc, indexVar, xFxBnd)
    ccall((:KN_get_var_fxbnd, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cdouble}), kc, indexVar, xFxBnd)
end

function KN_set_var_types(kc, nV, indexVars, xTypes)
    ccall((:KN_set_var_types, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cint}), kc, nV, indexVars, xTypes)
end

function KN_set_var_types_all(kc, xTypes)
    ccall((:KN_set_var_types_all, libknitro), Cint, (KN_context_ptr, Ptr{Cint}), kc, xTypes)
end

function KN_set_var_type(kc, indexVar, xType)
    ccall((:KN_set_var_type, libknitro), Cint, (KN_context_ptr, KNINT, Cint), kc, indexVar, xType)
end

function KN_get_var_types(kc, nV, indexVars, xTypes)
    ccall((:KN_get_var_types, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cint}), kc, nV, indexVars, xTypes)
end

function KN_get_var_types_all(kc, xTypes)
    ccall((:KN_get_var_types_all, libknitro), Cint, (KN_context_ptr, Ptr{Cint}), kc, xTypes)
end

function KN_get_var_type(kc, indexVar, xType)
    ccall((:KN_get_var_type, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cint}), kc, indexVar, xType)
end

function KN_set_var_properties(kc, nV, indexVars, xProperties)
    ccall((:KN_set_var_properties, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cint}), kc, nV, indexVars, xProperties)
end

function KN_set_var_properties_all(kc, xProperties)
    ccall((:KN_set_var_properties_all, libknitro), Cint, (KN_context_ptr, Ptr{Cint}), kc, xProperties)
end

function KN_set_var_property(kc, indexVar, xProperty)
    ccall((:KN_set_var_property, libknitro), Cint, (KN_context_ptr, KNINT, Cint), kc, indexVar, xProperty)
end

function KN_set_con_lobnds(kc, nC, indexCons, cLoBnds)
    ccall((:KN_set_con_lobnds, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nC, indexCons, cLoBnds)
end

function KN_set_con_lobnds_all(kc, cLoBnds)
    ccall((:KN_set_con_lobnds_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, cLoBnds)
end

function KN_set_con_lobnd(kc, indexCon, cLoBnd)
    ccall((:KN_set_con_lobnd, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexCon, cLoBnd)
end

function KN_set_con_upbnds(kc, nC, indexCons, cUpBnds)
    ccall((:KN_set_con_upbnds, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nC, indexCons, cUpBnds)
end

function KN_set_con_upbnds_all(kc, cUpBnds)
    ccall((:KN_set_con_upbnds_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, cUpBnds)
end

function KN_set_con_upbnd(kc, indexCon, cUpBnd)
    ccall((:KN_set_con_upbnd, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexCon, cUpBnd)
end

function KN_set_con_eqbnds(kc, nC, indexCons, cEqBnds)
    ccall((:KN_set_con_eqbnds, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nC, indexCons, cEqBnds)
end

function KN_set_con_eqbnds_all(kc, cEqBnds)
    ccall((:KN_set_con_eqbnds_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, cEqBnds)
end

function KN_set_con_eqbnd(kc, indexCon, cEqBnd)
    ccall((:KN_set_con_eqbnd, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexCon, cEqBnd)
end

function KN_get_con_lobnds(kc, nC, indexCons, cLoBnds)
    ccall((:KN_get_con_lobnds, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nC, indexCons, cLoBnds)
end

function KN_get_con_lobnds_all(kc, cLoBnds)
    ccall((:KN_get_con_lobnds_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, cLoBnds)
end

function KN_get_con_lobnd(kc, indexCon, cLoBnd)
    ccall((:KN_get_con_lobnd, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cdouble}), kc, indexCon, cLoBnd)
end

function KN_get_con_upbnds(kc, nC, indexCons, cUpBnds)
    ccall((:KN_get_con_upbnds, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nC, indexCons, cUpBnds)
end

function KN_get_con_upbnds_all(kc, cUpBnds)
    ccall((:KN_get_con_upbnds_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, cUpBnds)
end

function KN_get_con_upbnd(kc, indexCon, cUpBnd)
    ccall((:KN_get_con_upbnd, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cdouble}), kc, indexCon, cUpBnd)
end

function KN_get_con_eqbnds(kc, nC, indexCons, cEqBnds)
    ccall((:KN_get_con_eqbnds, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nC, indexCons, cEqBnds)
end

function KN_get_con_eqbnds_all(kc, cEqBnds)
    ccall((:KN_get_con_eqbnds_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, cEqBnds)
end

function KN_get_con_eqbnd(kc, indexCon, cEqBnd)
    ccall((:KN_get_con_eqbnd, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cdouble}), kc, indexCon, cEqBnd)
end

function KN_set_obj_property(kc, objProperty)
    ccall((:KN_set_obj_property, libknitro), Cint, (KN_context_ptr, Cint), kc, objProperty)
end

function KN_set_con_properties(kc, nC, indexCons, cProperties)
    ccall((:KN_set_con_properties, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cint}), kc, nC, indexCons, cProperties)
end

function KN_set_con_properties_all(kc, cProperties)
    ccall((:KN_set_con_properties_all, libknitro), Cint, (KN_context_ptr, Ptr{Cint}), kc, cProperties)
end

function KN_set_con_property(kc, indexCon, cProperty)
    ccall((:KN_set_con_property, libknitro), Cint, (KN_context_ptr, KNINT, Cint), kc, indexCon, cProperty)
end

function KN_set_obj_goal(kc, objGoal)
    ccall((:KN_set_obj_goal, libknitro), Cint, (KN_context_ptr, Cint), kc, objGoal)
end

function KN_set_var_primal_init_values(kc, nV, indexVars, xInitVals)
    ccall((:KN_set_var_primal_init_values, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nV, indexVars, xInitVals)
end

function KN_set_var_primal_init_values_all(kc, xInitVals)
    ccall((:KN_set_var_primal_init_values_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, xInitVals)
end

function KN_set_var_primal_init_value(kc, indexVar, xInitVal)
    ccall((:KN_set_var_primal_init_value, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexVar, xInitVal)
end

function KN_set_var_dual_init_values(kc, nV, indexVars, lambdaInitVals)
    ccall((:KN_set_var_dual_init_values, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nV, indexVars, lambdaInitVals)
end

function KN_set_var_dual_init_values_all(kc, lambdaInitVals)
    ccall((:KN_set_var_dual_init_values_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, lambdaInitVals)
end

function KN_set_var_dual_init_value(kc, indexVar, lambdaInitVal)
    ccall((:KN_set_var_dual_init_value, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexVar, lambdaInitVal)
end

function KN_set_con_dual_init_values(kc, nC, indexCons, lambdaInitVals)
    ccall((:KN_set_con_dual_init_values, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nC, indexCons, lambdaInitVals)
end

function KN_set_con_dual_init_values_all(kc, lambdaInitVals)
    ccall((:KN_set_con_dual_init_values_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, lambdaInitVals)
end

function KN_set_con_dual_init_value(kc, indexCon, lambdaInitVal)
    ccall((:KN_set_con_dual_init_value, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexCon, lambdaInitVal)
end

function KN_add_obj_constant(kc, constant)
    ccall((:KN_add_obj_constant, libknitro), Cint, (KN_context_ptr, Cdouble), kc, constant)
end

function KN_del_obj_constant(kc)
    ccall((:KN_del_obj_constant, libknitro), Cint, (KN_context_ptr,), kc)
end

function KN_chg_obj_constant(kc, constant)
    ccall((:KN_chg_obj_constant, libknitro), Cint, (KN_context_ptr, Cdouble), kc, constant)
end

function KN_add_con_constants(kc, nC, indexCons, constants)
    ccall((:KN_add_con_constants, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nC, indexCons, constants)
end

function KN_add_con_constants_all(kc, constants)
    ccall((:KN_add_con_constants_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, constants)
end

function KN_add_con_constant(kc, indexCon, constant)
    ccall((:KN_add_con_constant, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexCon, constant)
end

function KN_del_con_constants(kc, nC, indexCons)
    ccall((:KN_del_con_constants, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}), kc, nC, indexCons)
end

function KN_del_con_constants_all(kc)
    ccall((:KN_del_con_constants_all, libknitro), Cint, (KN_context_ptr,), kc)
end

function KN_del_con_constant(kc, indexCon)
    ccall((:KN_del_con_constant, libknitro), Cint, (KN_context_ptr, KNINT), kc, indexCon)
end

function KN_chg_con_constants(kc, nC, indexCons, constants)
    ccall((:KN_chg_con_constants, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nC, indexCons, constants)
end

function KN_chg_con_constants_all(kc, constants)
    ccall((:KN_chg_con_constants_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, constants)
end

function KN_chg_con_constant(kc, indexCon, constant)
    ccall((:KN_chg_con_constant, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexCon, constant)
end

function KN_add_rsd_constants(kc, nR, indexRsds, constants)
    ccall((:KN_add_rsd_constants, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nR, indexRsds, constants)
end

function KN_add_rsd_constants_all(kc, constants)
    ccall((:KN_add_rsd_constants_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, constants)
end

function KN_add_rsd_constant(kc, indexRsd, constant)
    ccall((:KN_add_rsd_constant, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexRsd, constant)
end

function KN_add_obj_linear_struct(kc, nnz, indexVars, coefs)
    ccall((:KN_add_obj_linear_struct, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nnz, indexVars, coefs)
end

function KN_add_obj_linear_term(kc, indexVar, coef)
    ccall((:KN_add_obj_linear_term, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexVar, coef)
end

function KN_del_obj_linear_struct(kc, nnz, indexVars)
    ccall((:KN_del_obj_linear_struct, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}), kc, nnz, indexVars)
end

function KN_del_obj_linear_term(kc, indexVar)
    ccall((:KN_del_obj_linear_term, libknitro), Cint, (KN_context_ptr, KNINT), kc, indexVar)
end

function KN_chg_obj_linear_struct(kc, nnz, indexVars, coefs)
    ccall((:KN_chg_obj_linear_struct, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nnz, indexVars, coefs)
end

function KN_chg_obj_linear_term(kc, indexVar, coef)
    ccall((:KN_chg_obj_linear_term, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexVar, coef)
end

function KN_add_con_linear_struct(kc, nnz, indexCons, indexVars, coefs)
    ccall((:KN_add_con_linear_struct, libknitro), Cint, (KN_context_ptr, KNLONG, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}), kc, nnz, indexCons, indexVars, coefs)
end

function KN_add_con_linear_struct_one(kc, nnz, indexCon, indexVars, coefs)
    ccall((:KN_add_con_linear_struct_one, libknitro), Cint, (KN_context_ptr, KNLONG, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nnz, indexCon, indexVars, coefs)
end

function KN_add_con_linear_term(kc, indexCon, indexVar, coef)
    ccall((:KN_add_con_linear_term, libknitro), Cint, (KN_context_ptr, KNINT, KNINT, Cdouble), kc, indexCon, indexVar, coef)
end

function KN_del_con_linear_struct(kc, nnz, indexCons, indexVars)
    ccall((:KN_del_con_linear_struct, libknitro), Cint, (KN_context_ptr, KNLONG, Ptr{KNINT}, Ptr{KNINT}), kc, nnz, indexCons, indexVars)
end

function KN_del_con_linear_struct_one(kc, nnz, indexCon, indexVars)
    ccall((:KN_del_con_linear_struct_one, libknitro), Cint, (KN_context_ptr, KNLONG, KNINT, Ptr{KNINT}), kc, nnz, indexCon, indexVars)
end

function KN_del_con_linear_term(kc, indexCon, indexVar)
    ccall((:KN_del_con_linear_term, libknitro), Cint, (KN_context_ptr, KNINT, KNINT), kc, indexCon, indexVar)
end

function KN_chg_con_linear_struct(kc, nnz, indexCons, indexVars, coefs)
    ccall((:KN_chg_con_linear_struct, libknitro), Cint, (KN_context_ptr, KNLONG, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}), kc, nnz, indexCons, indexVars, coefs)
end

function KN_chg_con_linear_struct_one(kc, nnz, indexCon, indexVars, coefs)
    ccall((:KN_chg_con_linear_struct_one, libknitro), Cint, (KN_context_ptr, KNLONG, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nnz, indexCon, indexVars, coefs)
end

function KN_chg_con_linear_term(kc, indexCon, indexVar, coef)
    ccall((:KN_chg_con_linear_term, libknitro), Cint, (KN_context_ptr, KNINT, KNINT, Cdouble), kc, indexCon, indexVar, coef)
end

function KN_add_rsd_linear_struct(kc, nnz, indexRsds, indexVars, coefs)
    ccall((:KN_add_rsd_linear_struct, libknitro), Cint, (KN_context_ptr, KNLONG, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}), kc, nnz, indexRsds, indexVars, coefs)
end

function KN_add_rsd_linear_struct_one(kc, nnz, indexRsd, indexVars, coefs)
    ccall((:KN_add_rsd_linear_struct_one, libknitro), Cint, (KN_context_ptr, KNLONG, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nnz, indexRsd, indexVars, coefs)
end

function KN_add_rsd_linear_term(kc, indexRsd, indexVar, coef)
    ccall((:KN_add_rsd_linear_term, libknitro), Cint, (KN_context_ptr, KNINT, KNINT, Cdouble), kc, indexRsd, indexVar, coef)
end

function KN_add_obj_quadratic_struct(kc, nnz, indexVars1, indexVars2, coefs)
    ccall((:KN_add_obj_quadratic_struct, libknitro), Cint, (KN_context_ptr, KNLONG, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}), kc, nnz, indexVars1, indexVars2, coefs)
end

function KN_add_obj_quadratic_term(kc, indexVar1, indexVar2, coef)
    ccall((:KN_add_obj_quadratic_term, libknitro), Cint, (KN_context_ptr, KNINT, KNINT, Cdouble), kc, indexVar1, indexVar2, coef)
end

function KN_add_con_quadratic_struct(kc, nnz, indexCons, indexVars1, indexVars2, coefs)
    ccall((:KN_add_con_quadratic_struct, libknitro), Cint, (KN_context_ptr, KNLONG, Ptr{KNINT}, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}), kc, nnz, indexCons, indexVars1, indexVars2, coefs)
end

function KN_add_con_quadratic_struct_one(kc, nnz, indexCon, indexVars1, indexVars2, coefs)
    ccall((:KN_add_con_quadratic_struct_one, libknitro), Cint, (KN_context_ptr, KNLONG, KNINT, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}), kc, nnz, indexCon, indexVars1, indexVars2, coefs)
end

function KN_add_con_quadratic_term(kc, indexCon, indexVar1, indexVar2, coef)
    ccall((:KN_add_con_quadratic_term, libknitro), Cint, (KN_context_ptr, KNINT, KNINT, KNINT, Cdouble), kc, indexCon, indexVar1, indexVar2, coef)
end

function KN_add_con_L2norm(kc, indexCon, nCoords, nnz, indexCoords, indexVars, coefs, constants)
    ccall((:KN_add_con_L2norm, libknitro), Cint, (KN_context_ptr, KNINT, KNINT, KNLONG, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}, Ptr{Cdouble}), kc, indexCon, nCoords, nnz, indexCoords, indexVars, coefs, constants)
end

function KN_set_compcons(kc, nCC, ccTypes, indexComps1, indexComps2)
    ccall((:KN_set_compcons, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cint}, Ptr{KNINT}, Ptr{KNINT}), kc, nCC, ccTypes, indexComps1, indexComps2)
end

function KN_load_mps_file(kc, filename)
    ccall((:KN_load_mps_file, libknitro), Cint, (KN_context_ptr, Ptr{Cchar}), kc, filename)
end

function KN_write_mps_file(kc, filename)
    ccall((:KN_write_mps_file, libknitro), Cint, (KN_context_ptr, Ptr{Cchar}), kc, filename)
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
    ccall((:KN_add_eval_callback, libknitro), Cint, (KN_context_ptr, KNBOOL, KNINT, Ptr{KNINT}, Ptr{Cvoid}, Ptr{CB_context_ptr}), kc, evalObj, nC, indexCons, funcCallback, cb)
end

function KN_add_eval_callback_all(kc, funcCallback, cb)
    ccall((:KN_add_eval_callback_all, libknitro), Cint, (KN_context_ptr, Ptr{Cvoid}, Ptr{CB_context_ptr}), kc, funcCallback, cb)
end

function KN_add_eval_callback_one(kc, index, funcCallback, cb)
    ccall((:KN_add_eval_callback_one, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cvoid}, Ptr{CB_context_ptr}), kc, index, funcCallback, cb)
end

function KN_add_lsq_eval_callback(kc, nR, indexRsds, rsdCallback, cb)
    ccall((:KN_add_lsq_eval_callback, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cvoid}, Ptr{CB_context_ptr}), kc, nR, indexRsds, rsdCallback, cb)
end

function KN_add_lsq_eval_callback_all(kc, rsdCallback, cb)
    ccall((:KN_add_lsq_eval_callback_all, libknitro), Cint, (KN_context_ptr, Ptr{Cvoid}, Ptr{CB_context_ptr}), kc, rsdCallback, cb)
end

function KN_add_lsq_eval_callback_one(kc, indexRsd, rsdCallback, cb)
    ccall((:KN_add_lsq_eval_callback_one, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cvoid}, Ptr{CB_context_ptr}), kc, indexRsd, rsdCallback, cb)
end

function KN_set_cb_grad(kc, cb, nV, objGradIndexVars, nnzJ, jacIndexCons, jacIndexVars, gradCallback)
    ccall((:KN_set_cb_grad, libknitro), Cint, (KN_context_ptr, CB_context_ptr, KNINT, Ptr{KNINT}, KNLONG, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cvoid}), kc, cb, nV, objGradIndexVars, nnzJ, jacIndexCons, jacIndexVars, gradCallback)
end

function KN_set_cb_hess(kc, cb, nnzH, hessIndexVars1, hessIndexVars2, hessCallback)
    ccall((:KN_set_cb_hess, libknitro), Cint, (KN_context_ptr, CB_context_ptr, KNLONG, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cvoid}), kc, cb, nnzH, hessIndexVars1, hessIndexVars2, hessCallback)
end

function KN_set_cb_rsd_jac(kc, cb, nnzJ, jacIndexRsds, jacIndexVars, rsdJacCallback)
    ccall((:KN_set_cb_rsd_jac, libknitro), Cint, (KN_context_ptr, CB_context_ptr, KNLONG, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cvoid}), kc, cb, nnzJ, jacIndexRsds, jacIndexVars, rsdJacCallback)
end

function KN_set_cb_user_params(kc, cb, userParams)
    ccall((:KN_set_cb_user_params, libknitro), Cint, (KN_context_ptr, CB_context_ptr, Ptr{Cvoid}), kc, cb, userParams)
end

function KN_set_cb_gradopt(kc, cb, gradopt)
    ccall((:KN_set_cb_gradopt, libknitro), Cint, (KN_context_ptr, CB_context_ptr, Cint), kc, cb, gradopt)
end

function KN_set_cb_relstepsizes(kc, cb, nV, indexVars, xRelStepSizes)
    ccall((:KN_set_cb_relstepsizes, libknitro), Cint, (KN_context_ptr, CB_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, cb, nV, indexVars, xRelStepSizes)
end

function KN_set_cb_relstepsizes_all(kc, cb, xRelStepSizes)
    ccall((:KN_set_cb_relstepsizes_all, libknitro), Cint, (KN_context_ptr, CB_context_ptr, Ptr{Cdouble}), kc, cb, xRelStepSizes)
end

function KN_set_cb_relstepsize(kc, cb, indexVar, xRelStepSize)
    ccall((:KN_set_cb_relstepsize, libknitro), Cint, (KN_context_ptr, CB_context_ptr, KNINT, Cdouble), kc, cb, indexVar, xRelStepSize)
end

function KN_get_cb_number_cons(kc, cb, nC)
    ccall((:KN_get_cb_number_cons, libknitro), Cint, (KN_context_ptr, CB_context_ptr, Ptr{KNINT}), kc, cb, nC)
end

function KN_get_cb_number_rsds(kc, cb, nR)
    ccall((:KN_get_cb_number_rsds, libknitro), Cint, (KN_context_ptr, CB_context_ptr, Ptr{KNINT}), kc, cb, nR)
end

function KN_get_cb_objgrad_nnz(kc, cb, nnz)
    ccall((:KN_get_cb_objgrad_nnz, libknitro), Cint, (KN_context_ptr, CB_context_ptr, Ptr{KNINT}), kc, cb, nnz)
end

function KN_get_cb_jacobian_nnz(kc, cb, nnz)
    ccall((:KN_get_cb_jacobian_nnz, libknitro), Cint, (KN_context_ptr, CB_context_ptr, Ptr{KNLONG}), kc, cb, nnz)
end

function KN_get_cb_rsd_jacobian_nnz(kc, cb, nnz)
    ccall((:KN_get_cb_rsd_jacobian_nnz, libknitro), Cint, (KN_context_ptr, CB_context_ptr, Ptr{KNLONG}), kc, cb, nnz)
end

function KN_get_cb_hessian_nnz(kc, cb, nnz)
    ccall((:KN_get_cb_hessian_nnz, libknitro), Cint, (KN_context_ptr, CB_context_ptr, Ptr{KNLONG}), kc, cb, nnz)
end

# typedef int KN_user_callback ( KN_context_ptr kc , const double * const x , const double * const lambda , void * const userParams )
const KN_user_callback = Cvoid

function KN_set_newpt_callback(kc, fnPtr, userParams)
    ccall((:KN_set_newpt_callback, libknitro), Cint, (KN_context_ptr, Ptr{Cvoid}, Ptr{Cvoid}), kc, fnPtr, userParams)
end

function KN_set_mip_node_callback(kc, fnPtr, userParams)
    ccall((:KN_set_mip_node_callback, libknitro), Cint, (KN_context_ptr, Ptr{Cvoid}, Ptr{Cvoid}), kc, fnPtr, userParams)
end

function KN_set_ms_process_callback(kc, fnPtr, userParams)
    ccall((:KN_set_ms_process_callback, libknitro), Cint, (KN_context_ptr, Ptr{Cvoid}, Ptr{Cvoid}), kc, fnPtr, userParams)
end

# typedef int KN_ms_initpt_callback ( KN_context_ptr kc , const KNINT nSolveNumber , double * const x , double * const lambda , void * const userParams )
const KN_ms_initpt_callback = Cvoid

function KN_set_ms_initpt_callback(kc, fnPtr, userParams)
    ccall((:KN_set_ms_initpt_callback, libknitro), Cint, (KN_context_ptr, Ptr{Cvoid}, Ptr{Cvoid}), kc, fnPtr, userParams)
end

# typedef int KN_puts ( const char * const str , void * const userParams )
const KN_puts = Cvoid

function KN_set_puts_callback(kc, fnPtr, userParams)
    ccall((:KN_set_puts_callback, libknitro), Cint, (KN_context_ptr, Ptr{Cvoid}, Ptr{Cvoid}), kc, fnPtr, userParams)
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
    ccall((:KN_set_linsolver_callback, libknitro), Cint, (KN_context_ptr, Ptr{Cvoid}, Ptr{Cvoid}), kc, fnPtr, userParams)
end

function KN_load_lp(kc, n, lobjCoefs, xLoBnds, xUpBnds, m, cLoBnds, cUpBnds, nnzJ, ljacIndexCons, ljacIndexVars, ljacCoefs)
    ccall((:KN_load_lp, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, KNINT, Ptr{Cdouble}, Ptr{Cdouble}, KNLONG, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}), kc, n, lobjCoefs, xLoBnds, xUpBnds, m, cLoBnds, cUpBnds, nnzJ, ljacIndexCons, ljacIndexVars, ljacCoefs)
end

function KN_load_qp(kc, n, lobjCoefs, xLoBnds, xUpBnds, m, cLoBnds, cUpBnds, nnzJ, ljacIndexCons, ljacIndexVars, ljacCoefs, nnzH, qobjIndexVars1, qobjIndexVars2, qobjCoefs)
    ccall((:KN_load_qp, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, KNINT, Ptr{Cdouble}, Ptr{Cdouble}, KNLONG, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}, KNLONG, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}), kc, n, lobjCoefs, xLoBnds, xUpBnds, m, cLoBnds, cUpBnds, nnzJ, ljacIndexCons, ljacIndexVars, ljacCoefs, nnzH, qobjIndexVars1, qobjIndexVars2, qobjCoefs)
end

function KN_load_qcqp(kc, n, lobjCoefs, xLoBnds, xUpBnds, m, cLoBnds, cUpBnds, nnzJ, ljacIndexCons, ljacIndexVars, ljacCoefs, nnzH, qobjIndexVars1, qobjIndexVars2, qobjCoefs, nnzQ, qconIndexCons, qconIndexVars1, qconIndexVars2, qconCoefs)
    ccall((:KN_load_qcqp, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, KNINT, Ptr{Cdouble}, Ptr{Cdouble}, KNLONG, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}, KNLONG, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}, KNLONG, Ptr{KNINT}, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}), kc, n, lobjCoefs, xLoBnds, xUpBnds, m, cLoBnds, cUpBnds, nnzJ, ljacIndexCons, ljacIndexVars, ljacCoefs, nnzH, qobjIndexVars1, qobjIndexVars2, qobjCoefs, nnzQ, qconIndexCons, qconIndexVars1, qconIndexVars2, qconCoefs)
end

function KN_set_var_feastols(kc, nV, indexVars, xFeasTols)
    ccall((:KN_set_var_feastols, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nV, indexVars, xFeasTols)
end

function KN_set_var_feastols_all(kc, xFeasTols)
    ccall((:KN_set_var_feastols_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, xFeasTols)
end

function KN_set_var_feastol(kc, indexVar, xFeasTol)
    ccall((:KN_set_var_feastol, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexVar, xFeasTol)
end

function KN_set_con_feastols(kc, nC, indexCons, cFeasTols)
    ccall((:KN_set_con_feastols, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nC, indexCons, cFeasTols)
end

function KN_set_con_feastols_all(kc, cFeasTols)
    ccall((:KN_set_con_feastols_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, cFeasTols)
end

function KN_set_con_feastol(kc, indexCon, cFeasTol)
    ccall((:KN_set_con_feastol, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexCon, cFeasTol)
end

function KN_set_compcon_feastols(kc, nCC, indexCompCons, ccFeasTols)
    ccall((:KN_set_compcon_feastols, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nCC, indexCompCons, ccFeasTols)
end

function KN_set_compcon_feastols_all(kc, ccFeasTols)
    ccall((:KN_set_compcon_feastols_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, ccFeasTols)
end

function KN_set_compcon_feastol(kc, indexCompCon, ccFeasTol)
    ccall((:KN_set_compcon_feastol, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexCompCon, ccFeasTol)
end

function KN_set_var_scalings(kc, nV, indexVars, xScaleFactors, xScaleCenters)
    ccall((:KN_set_var_scalings, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}, Ptr{Cdouble}), kc, nV, indexVars, xScaleFactors, xScaleCenters)
end

function KN_set_var_scalings_all(kc, xScaleFactors, xScaleCenters)
    ccall((:KN_set_var_scalings_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}, Ptr{Cdouble}), kc, xScaleFactors, xScaleCenters)
end

function KN_set_var_scaling(kc, indexVar, xScaleFactor, xScaleCenter)
    ccall((:KN_set_var_scaling, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble, Cdouble), kc, indexVar, xScaleFactor, xScaleCenter)
end

function KN_set_con_scalings(kc, nC, indexCons, cScaleFactors)
    ccall((:KN_set_con_scalings, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nC, indexCons, cScaleFactors)
end

function KN_set_con_scalings_all(kc, cScaleFactors)
    ccall((:KN_set_con_scalings_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, cScaleFactors)
end

function KN_set_con_scaling(kc, indexCon, cScaleFactor)
    ccall((:KN_set_con_scaling, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexCon, cScaleFactor)
end

function KN_set_compcon_scalings(kc, nCC, indexCompCons, ccScaleFactors)
    ccall((:KN_set_compcon_scalings, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nCC, indexCompCons, ccScaleFactors)
end

function KN_set_compcon_scalings_all(kc, ccScaleFactors)
    ccall((:KN_set_compcon_scalings_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, ccScaleFactors)
end

function KN_set_compcon_scaling(kc, indexCompCons, ccScaleFactor)
    ccall((:KN_set_compcon_scaling, libknitro), Cint, (KN_context_ptr, KNINT, Cdouble), kc, indexCompCons, ccScaleFactor)
end

function KN_set_obj_scaling(kc, objScaleFactor)
    ccall((:KN_set_obj_scaling, libknitro), Cint, (KN_context_ptr, Cdouble), kc, objScaleFactor)
end

function KN_set_var_names(kc, nV, indexVars, xNames)
    ccall((:KN_set_var_names, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Ptr{Cchar}}), kc, nV, indexVars, xNames)
end

function KN_set_var_names_all(kc, xNames)
    ccall((:KN_set_var_names_all, libknitro), Cint, (KN_context_ptr, Ptr{Ptr{Cchar}}), kc, xNames)
end

function KN_set_var_name(kc, indexVars, xName)
    ccall((:KN_set_var_name, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cchar}), kc, indexVars, xName)
end

function KN_set_con_names(kc, nC, indexCons, cNames)
    ccall((:KN_set_con_names, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Ptr{Cchar}}), kc, nC, indexCons, cNames)
end

function KN_set_con_names_all(kc, cNames)
    ccall((:KN_set_con_names_all, libknitro), Cint, (KN_context_ptr, Ptr{Ptr{Cchar}}), kc, cNames)
end

function KN_set_con_name(kc, indexCon, cName)
    ccall((:KN_set_con_name, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cchar}), kc, indexCon, cName)
end

function KN_set_compcon_names(kc, nCC, indexCompCons, ccNames)
    ccall((:KN_set_compcon_names, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Ptr{Cchar}}), kc, nCC, indexCompCons, ccNames)
end

function KN_set_compcon_names_all(kc, ccNames)
    ccall((:KN_set_compcon_names_all, libknitro), Cint, (KN_context_ptr, Ptr{Ptr{Cchar}}), kc, ccNames)
end

function KN_set_compcon_name(kc, indexCompCon, ccName)
    ccall((:KN_set_compcon_name, libknitro), Cint, (KN_context_ptr, Cint, Ptr{Cchar}), kc, indexCompCon, ccName)
end

function KN_set_obj_name(kc, objName)
    ccall((:KN_set_obj_name, libknitro), Cint, (KN_context_ptr, Ptr{Cchar}), kc, objName)
end

function KN_get_var_names(kc, nV, indexVars, nBufferSize, xNames)
    ccall((:KN_get_var_names, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, KNINT, Ptr{Ptr{Cchar}}), kc, nV, indexVars, nBufferSize, xNames)
end

function KN_get_var_names_all(kc, nBufferSize, xNames)
    ccall((:KN_get_var_names_all, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Ptr{Cchar}}), kc, nBufferSize, xNames)
end

function KN_get_var_name(kc, indexVars, nBufferSize, xName)
    ccall((:KN_get_var_name, libknitro), Cint, (KN_context_ptr, KNINT, KNINT, Ptr{Cchar}), kc, indexVars, nBufferSize, xName)
end

function KN_get_con_names(kc, nC, indexCons, nBufferSize, cNames)
    ccall((:KN_get_con_names, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, KNINT, Ptr{Ptr{Cchar}}), kc, nC, indexCons, nBufferSize, cNames)
end

function KN_get_con_names_all(kc, nBufferSize, cNames)
    ccall((:KN_get_con_names_all, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Ptr{Cchar}}), kc, nBufferSize, cNames)
end

function KN_get_con_name(kc, indexCons, nBufferSize, cName)
    ccall((:KN_get_con_name, libknitro), Cint, (KN_context_ptr, KNINT, KNINT, Ptr{Cchar}), kc, indexCons, nBufferSize, cName)
end

function KN_set_var_honorbnds(kc, nV, indexVars, xHonorBnds)
    ccall((:KN_set_var_honorbnds, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cint}), kc, nV, indexVars, xHonorBnds)
end

function KN_set_var_honorbnds_all(kc, xHonorBnds)
    ccall((:KN_set_var_honorbnds_all, libknitro), Cint, (KN_context_ptr, Ptr{Cint}), kc, xHonorBnds)
end

function KN_set_var_honorbnd(kc, indexVar, xHonorBnd)
    ccall((:KN_set_var_honorbnd, libknitro), Cint, (KN_context_ptr, KNINT, Cint), kc, indexVar, xHonorBnd)
end

function KN_set_mip_branching_priorities(kc, nV, indexVars, xPriorities)
    ccall((:KN_set_mip_branching_priorities, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cint}), kc, nV, indexVars, xPriorities)
end

function KN_set_mip_branching_priorities_all(kc, xPriorities)
    ccall((:KN_set_mip_branching_priorities_all, libknitro), Cint, (KN_context_ptr, Ptr{Cint}), kc, xPriorities)
end

function KN_set_mip_branching_priority(kc, indexVar, xPriority)
    ccall((:KN_set_mip_branching_priority, libknitro), Cint, (KN_context_ptr, KNINT, Cint), kc, indexVar, xPriority)
end

function KN_set_mip_intvar_strategies(kc, nV, indexVars, xStrategies)
    ccall((:KN_set_mip_intvar_strategies, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cint}), kc, nV, indexVars, xStrategies)
end

function KN_set_mip_intvar_strategies_all(kc, xStrategies)
    ccall((:KN_set_mip_intvar_strategies_all, libknitro), Cint, (KN_context_ptr, Ptr{Cint}), kc, xStrategies)
end

function KN_set_mip_intvar_strategy(kc, indexVar, xStrategy)
    ccall((:KN_set_mip_intvar_strategy, libknitro), Cint, (KN_context_ptr, KNINT, Cint), kc, indexVar, xStrategy)
end

function KN_solve(kc)
    ccall((:KN_solve, libknitro), Cint, (KN_context_ptr,), kc)
end

function KN_get_number_vars(kc, nV)
    ccall((:KN_get_number_vars, libknitro), Cint, (KN_context_ptr, Ptr{KNINT}), kc, nV)
end

function KN_get_number_cons(kc, nC)
    ccall((:KN_get_number_cons, libknitro), Cint, (KN_context_ptr, Ptr{KNINT}), kc, nC)
end

function KN_get_number_compcons(kc, nCC)
    ccall((:KN_get_number_compcons, libknitro), Cint, (KN_context_ptr, Ptr{KNINT}), kc, nCC)
end

function KN_get_number_rsds(kc, nR)
    ccall((:KN_get_number_rsds, libknitro), Cint, (KN_context_ptr, Ptr{KNINT}), kc, nR)
end

function KN_get_number_FC_evals(kc, numFCevals)
    ccall((:KN_get_number_FC_evals, libknitro), Cint, (KN_context_ptr, Ptr{Cint}), kc, numFCevals)
end

function KN_get_number_GA_evals(kc, numGAevals)
    ccall((:KN_get_number_GA_evals, libknitro), Cint, (KN_context_ptr, Ptr{Cint}), kc, numGAevals)
end

function KN_get_number_H_evals(kc, numHevals)
    ccall((:KN_get_number_H_evals, libknitro), Cint, (KN_context_ptr, Ptr{Cint}), kc, numHevals)
end

function KN_get_number_HV_evals(kc, numHVevals)
    ccall((:KN_get_number_HV_evals, libknitro), Cint, (KN_context_ptr, Ptr{Cint}), kc, numHVevals)
end

function KN_get_solve_time_cpu(kc, time)
    ccall((:KN_get_solve_time_cpu, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, time)
end

function KN_get_solve_time_real(kc, time)
    ccall((:KN_get_solve_time_real, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, time)
end

function KN_get_solution(kc, status, obj, x, lambda)
    ccall((:KN_get_solution, libknitro), Cint, (KN_context_ptr, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}), kc, status, obj, x, lambda)
end

function KN_get_obj_value(kc, obj)
    ccall((:KN_get_obj_value, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, obj)
end

function KN_get_obj_type(kc, objType)
    ccall((:KN_get_obj_type, libknitro), Cint, (KN_context_ptr, Ptr{Cint}), kc, objType)
end

function KN_get_var_primal_values(kc, nV, indexVars, x)
    ccall((:KN_get_var_primal_values, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nV, indexVars, x)
end

function KN_get_var_primal_values_all(kc, x)
    ccall((:KN_get_var_primal_values_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, x)
end

function KN_get_var_primal_value(kc, indexVar, x)
    ccall((:KN_get_var_primal_value, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cdouble}), kc, indexVar, x)
end

function KN_get_var_dual_values(kc, nV, indexVars, lambda)
    ccall((:KN_get_var_dual_values, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nV, indexVars, lambda)
end

function KN_get_var_dual_values_all(kc, lambda)
    ccall((:KN_get_var_dual_values_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, lambda)
end

function KN_get_var_dual_value(kc, indexVar, lambda)
    ccall((:KN_get_var_dual_value, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cdouble}), kc, indexVar, lambda)
end

function KN_get_con_dual_values(kc, nC, indexCons, lambda)
    ccall((:KN_get_con_dual_values, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nC, indexCons, lambda)
end

function KN_get_con_dual_values_all(kc, lambda)
    ccall((:KN_get_con_dual_values_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, lambda)
end

function KN_get_con_dual_value(kc, indexCons, lambda)
    ccall((:KN_get_con_dual_value, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cdouble}), kc, indexCons, lambda)
end

function KN_get_con_values(kc, nC, indexCons, c)
    ccall((:KN_get_con_values, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nC, indexCons, c)
end

function KN_get_con_values_all(kc, c)
    ccall((:KN_get_con_values_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, c)
end

function KN_get_con_value(kc, indexCon, c)
    ccall((:KN_get_con_value, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cdouble}), kc, indexCon, c)
end

function KN_get_con_types(kc, nC, indexCons, cTypes)
    ccall((:KN_get_con_types, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cint}), kc, nC, indexCons, cTypes)
end

function KN_get_con_types_all(kc, cTypes)
    ccall((:KN_get_con_types_all, libknitro), Cint, (KN_context_ptr, Ptr{Cint}), kc, cTypes)
end

function KN_get_con_type(kc, indexCon, cType)
    ccall((:KN_get_con_type, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cint}), kc, indexCon, cType)
end

function KN_get_rsd_values(kc, nR, indexRsds, r)
    ccall((:KN_get_rsd_values, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, nR, indexRsds, r)
end

function KN_get_rsd_values_all(kc, r)
    ccall((:KN_get_rsd_values_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, r)
end

function KN_get_rsd_value(kc, indexRsd, r)
    ccall((:KN_get_rsd_value, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{Cdouble}), kc, indexRsd, r)
end

function KN_get_var_viols(kc, nV, indexVars, bndInfeas, intInfeas, viols)
    ccall((:KN_get_var_viols, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}), kc, nV, indexVars, bndInfeas, intInfeas, viols)
end

function KN_get_var_viols_all(kc, bndInfeas, intInfeas, viols)
    ccall((:KN_get_var_viols_all, libknitro), Cint, (KN_context_ptr, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}), kc, bndInfeas, intInfeas, viols)
end

function KN_get_var_viol(kc, indexVar, bndInfeas, intInfeas, viol)
    ccall((:KN_get_var_viol, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}), kc, indexVar, bndInfeas, intInfeas, viol)
end

function KN_get_con_viols(kc, nC, indexCons, infeas, viols)
    ccall((:KN_get_con_viols, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}), kc, nC, indexCons, infeas, viols)
end

function KN_get_con_viols_all(kc, infeas, viols)
    ccall((:KN_get_con_viols_all, libknitro), Cint, (KN_context_ptr, Ptr{KNINT}, Ptr{Cdouble}), kc, infeas, viols)
end

function KN_get_con_viol(kc, indexCon, infeas, viol)
    ccall((:KN_get_con_viol, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, indexCon, infeas, viol)
end

function KN_get_presolve_error(kc, component, index, error, viol)
    ccall((:KN_get_presolve_error, libknitro), Cint, (KN_context_ptr, Ptr{KNINT}, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}), kc, component, index, error, viol)
end

function KN_get_number_iters(kc, numIters)
    ccall((:KN_get_number_iters, libknitro), Cint, (KN_context_ptr, Ptr{Cint}), kc, numIters)
end

function KN_get_number_cg_iters(kc, numCGiters)
    ccall((:KN_get_number_cg_iters, libknitro), Cint, (KN_context_ptr, Ptr{Cint}), kc, numCGiters)
end

function KN_get_abs_feas_error(kc, absFeasError)
    ccall((:KN_get_abs_feas_error, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, absFeasError)
end

function KN_get_rel_feas_error(kc, relFeasError)
    ccall((:KN_get_rel_feas_error, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, relFeasError)
end

function KN_get_abs_opt_error(kc, absOptError)
    ccall((:KN_get_abs_opt_error, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, absOptError)
end

function KN_get_rel_opt_error(kc, relOptError)
    ccall((:KN_get_rel_opt_error, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, relOptError)
end

function KN_get_objgrad_nnz(kc, nnz)
    ccall((:KN_get_objgrad_nnz, libknitro), Cint, (KN_context_ptr, Ptr{KNINT}), kc, nnz)
end

function KN_get_objgrad_values(kc, indexVars, objGrad)
    ccall((:KN_get_objgrad_values, libknitro), Cint, (KN_context_ptr, Ptr{KNINT}, Ptr{Cdouble}), kc, indexVars, objGrad)
end

function KN_get_objgrad_values_all(kc, objGrad)
    ccall((:KN_get_objgrad_values_all, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, objGrad)
end

function KN_get_jacobian_nnz(kc, nnz)
    ccall((:KN_get_jacobian_nnz, libknitro), Cint, (KN_context_ptr, Ptr{KNLONG}), kc, nnz)
end

function KN_get_jacobian_values(kc, indexCons, indexVars, jac)
    ccall((:KN_get_jacobian_values, libknitro), Cint, (KN_context_ptr, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}), kc, indexCons, indexVars, jac)
end

function KN_get_jacobian_nnz_one(kc, indexCon, nnz)
    ccall((:KN_get_jacobian_nnz_one, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}), kc, indexCon, nnz)
end

function KN_get_jacobian_values_one(kc, indexCon, indexVars, jac)
    ccall((:KN_get_jacobian_values_one, libknitro), Cint, (KN_context_ptr, KNINT, Ptr{KNINT}, Ptr{Cdouble}), kc, indexCon, indexVars, jac)
end

function KN_get_rsd_jacobian_nnz(kc, nnz)
    ccall((:KN_get_rsd_jacobian_nnz, libknitro), Cint, (KN_context_ptr, Ptr{KNLONG}), kc, nnz)
end

function KN_get_rsd_jacobian_values(kc, indexRsds, indexVars, rsdJac)
    ccall((:KN_get_rsd_jacobian_values, libknitro), Cint, (KN_context_ptr, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}), kc, indexRsds, indexVars, rsdJac)
end

function KN_get_hessian_nnz(kc, nnz)
    ccall((:KN_get_hessian_nnz, libknitro), Cint, (KN_context_ptr, Ptr{KNLONG}), kc, nnz)
end

function KN_get_hessian_values(kc, indexVars1, indexVars2, hess)
    ccall((:KN_get_hessian_values, libknitro), Cint, (KN_context_ptr, Ptr{KNINT}, Ptr{KNINT}, Ptr{Cdouble}), kc, indexVars1, indexVars2, hess)
end

function KN_get_mip_number_nodes(kc, numNodes)
    ccall((:KN_get_mip_number_nodes, libknitro), Cint, (KN_context_ptr, Ptr{Cint}), kc, numNodes)
end

function KN_get_mip_number_solves(kc, numSolves)
    ccall((:KN_get_mip_number_solves, libknitro), Cint, (KN_context_ptr, Ptr{Cint}), kc, numSolves)
end

function KN_get_mip_abs_gap(kc, absGap)
    ccall((:KN_get_mip_abs_gap, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, absGap)
end

function KN_get_mip_rel_gap(kc, relGap)
    ccall((:KN_get_mip_rel_gap, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, relGap)
end

function KN_get_mip_incumbent_obj(kc, incumbentObj)
    ccall((:KN_get_mip_incumbent_obj, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, incumbentObj)
end

function KN_get_mip_relaxation_bnd(kc, relaxBound)
    ccall((:KN_get_mip_relaxation_bnd, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, relaxBound)
end

function KN_get_mip_lastnode_obj(kc, lastNodeObj)
    ccall((:KN_get_mip_lastnode_obj, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, lastNodeObj)
end

function KN_get_mip_incumbent_x(kc, x)
    ccall((:KN_get_mip_incumbent_x, libknitro), Cint, (KN_context_ptr, Ptr{Cdouble}), kc, x)
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

const KN_PARAM_ALGORITHM = 1003

const KN_PARAM_ALG = 1003

const KN_ALG_AUTOMATIC = 0

const KN_ALG_AUTO = 0

const KN_ALG_BAR_DIRECT = 1

const KN_ALG_BAR_CG = 2

const KN_ALG_ACT_CG = 3

const KN_ALG_ACT_SQP = 4

const KN_ALG_MULTI = 5

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

const KN_BLASOPTION_KNITRO = 0

const KN_BLASOPTION_INTEL = 1

const KN_BLASOPTION_DYNAMIC = 2

const KN_BLASOPTION_BLIS = 3

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

const KN_ACT_LPALG_DUAL = 2

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

const KN_MIP_KNAPSACK_NO = 0

const KN_MIP_KNAPSACK_NONE = 0

const KN_MIP_KNAPSACK_INEQ = 1

const KN_MIP_KNAPSACK_LIFTED = 2

const KN_MIP_KNAPSACK_ALL = 3

const KN_PARAM_MIP_ROUNDING = 2017

const KN_MIP_ROUND_AUTO = -1

const KN_MIP_ROUND_NONE = 0

const KN_MIP_ROUND_HEURISTIC = 2

const KN_MIP_ROUND_NLP_SOME = 3

const KN_MIP_ROUND_NLP_ALWAYS = 4

const KN_PARAM_MIP_ROOTALG = 2018

const KN_MIP_ROOTALG_AUTO = 0

const KN_MIP_ROOTALG_BAR_DIRECT = 1

const KN_MIP_ROOTALG_BAR_CG = 2

const KN_MIP_ROOTALG_ACT_CG = 3

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

const KN_PARAM_MIP_NODEALG = 2032

const KN_MIP_NODEALG_AUTO = 0

const KN_MIP_NODEALG_BAR_DIRECT = 1

const KN_MIP_NODEALG_BAR_CG = 2

const KN_MIP_NODEALG_ACT_CG = 3

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

const KN_MIP_ZEROHALF_NONE = 0

const KN_MIP_ZEROHALF_ROOT = 1

const KN_MIP_ZEROHALF_TREE = 2

const KN_MIP_ZEROHALF_ALL = 3

const KN_PARAM_MIP_MIR = 2037

const KN_MIP_MIR_AUTO = -1

const KN_MIP_MIR_NONE = 0

const KN_MIP_MIR_TREE = 1

const KN_MIP_MIR_NLP = 2

const KN_PARAM_MIP_CLIQUE = 2038

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

const KN_MIP_LIFTPROJECT_NONE = 0

const KN_MIP_LIFTPROJECT_ROOT = 1

const KN_PARAM_MIP_NUMTHREADS = 2048

const KN_PARAM_PAR_NUMTHREADS = 3001

const KN_PARAM_PAR_CONCURRENT_EVALS = 3002

const KN_PAR_CONCURRENT_EVALS_NO = 0

const KN_PAR_CONCURRENT_EVALS_YES = 1

const KN_PARAM_PAR_BLASNUMTHREADS = 3003

const KN_PARAM_PAR_LSNUMTHREADS = 3004

const KN_PARAM_PAR_MSNUMTHREADS = 3005

const KN_PAR_MSNUMTHREADS_AUTO = 0

const KN_PARAM_PAR_CONICNUMTHREADS = 3006
