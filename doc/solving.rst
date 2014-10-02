-----------------------------
Creating and solving problems
-----------------------------
Problem structure is passed to KNITRO using ``init_problem``.

The problem is solved by calling ``solve_problem``.  Applications must provide a means of evaluating the nonlinear objective, constraints, first derivatives, and (optionally) second derivatives.  (First derivatives are also optional, but highly recommended.)

The typical calling sequence is:

.. code-block:: julia

    createProblem()
    init_problem()
    set_xxx_param (set any number of parameters)
    solve_problem() (a single call, or a reverse communications loop)

Calling sequence if the same problem is to be solved again, with different parameters or a different start point (see ``examples/hs035_restart.jl``):

.. code-block:: julia

    createProblem
    init_problem
    set_xxx_param (set any number of parameters)
    solve_problem (a single call, or a reverse communications loop)
    restart_problem
    set_xxx_param (set any number of parameters)
    solve_problem (a single call, or a reverse communications loop)

For MIP problems, use ``mip_init_problem`` and ``mip_solve`` instead (see ``examples/minlp.jl``).

If the application provides callback functions for making evaluations, then a single call to KTR_solve will return the solution. Alternatively, the application can employ a reverse communications driver. In this case, ``solve_problem`` returns a status code whenever it needs evaluation data (see ``examples/qcqp_reversecomm.jl``).
