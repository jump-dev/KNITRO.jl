--------------------------------------
Changing and reading solver parameters
--------------------------------------
Parameters cannot be set after KNITRO begins solving; i.e. after ``solve_problem`` is called.  They may be set again after ``restart_problem``. In most cases, parameter values are not validated until ``init_problem`` or ``solve_problem`` is called.

Parameters may be set using their integer identifier, e.g.

.. code-block:: julia

  set_param(kp, KTR_PARAM_OUTLEV, KTR_OUTLEV_ALL)
  set_param(kp, KTR_PARAM_MIP_OUTINTERVAL, int32(1))
  set_param(kp, KTR_PARAM_MIP_MAXNODES, int32(10000))

or using their string names, e.g.

.. code-block:: julia

  set_param(kp, "mip_method", KTR_MIP_METHOD_BB)
  set_param(kp, "algorithm", KTR_ALG_ACT_CG)
  set_param(kp, "outmode", KTR_OUTMODE_SCREEN)

The full list of integer identifiers are available in ``src/ktr_defines.jl``, and prefixed by ``KTR_PARAM_``. For more details, see the `official documentation <https://www.artelys.com/tools/knitro_doc/3_referenceManual/callableLibrary/API.html>`_.
