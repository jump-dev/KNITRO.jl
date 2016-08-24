
### Changing and reading solver parameters
Parameters cannot be set after Artelys Knitro begins solving; i.e. after `solveProblem` is called.  They may be set again after `restart_problem`. In most cases, parameter values are not validated until `initializeProblem` or `solveProblem` is called.

**Note:** The `gradopt` and `hessopt` [user options](https://www.artelys.com/tools/knitro_doc/3_referenceManual/userOptions.html) must be set before calling `initializeProblem`, and cannot be changed after calling these functions.

### Programmatic Interface
Parameters may be set using their integer identifier, e.g.

```julia
setOption(kp, KTR_PARAM_OUTLEV, KTR_OUTLEV_ALL)
setOption(kp, KTR_PARAM_MIP_OUTINTERVAL, 1)
setOption(kp, KTR_PARAM_MIP_MAXNODES, 10000)
```

or using their string names, e.g.

```julia
setOption(kp, "mip_method", KTR_MIP_METHOD_BB)
setOption(kp, "algorithm", KTR_ALG_ACT_CG)
setOption(kp, "outmode", KTR_OUTMODE_SCREEN)
```

The full list of integer identifiers are available in `src/ktr_defines.jl`, and prefixed by `KTR_PARAM_`. For more details, see the [official documentation](https://www.artelys.com/tools/knitro_doc/3_referenceManual/callableLibrary/API.html).
