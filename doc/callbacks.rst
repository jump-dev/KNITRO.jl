---------
Callbacks
---------
Applications may define functions for evaluating problem elements at a trial point.  The functions must match the prototype defined below, and passed to KNITRO with the appropriate ``set_func_x`` call.

KNITRO may request four different types of evaluation information, as specified in `evalRequestCode`:

.. code-block:: julia

    KTR_RC_EVALFC - return objective and constraint function values
    KTR_RC_EVALGA - return first derivative values in "objGrad" and "jac"
    KTR_RC_EVALH  - return second derivative values in "hessian"
    KTR_RC_EVALH_NO_F  (this version exclude the objective term)
    KTR_RC_EVALHV - return a Hessian-vector product in "hessVector"
    KTR_RC_EVALHV_NO_F (this version exclude the objective term)

The argument ``lambda`` is not defined when requesting EVALFC or EVALGA.

Usually, applications define 3 callback functions, one for EVALFC, one for EVALGA, and one for EVALH / EVALHV.  The last function evaluates H or HV depending on the value of ``evalRequestCode``.

It is possible (but ``Knitro.jl`` doesn't yet provide the convenience functions) to combine EVALFC and EVALGA into a single function, because "x" changes only for an EVALFC request.  This is advantageous if the application evaluates functions and their derivatives at the same time.

Pass the same callback function in ``set_func_callback`` and ``set_grad_callback``, have it populate ``obj``, ``c``, ``objGrad``, and ``jac`` for an EVALFC request, and do nothing for an EVALGA request.

Do not combine EVALFC and EVALGA if ``hessopt = KTR_HESSOPT_FINITE_DIFF``, because the finite difference Hessian changes ``x`` and calls EVALGA without calling EVALFC first. It is not possible to combine EVALH / EVALHV because ``lambda`` changes after the EVALFC call.
