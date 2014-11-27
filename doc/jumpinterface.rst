--------------
JuMP interface
--------------
You can also work with KNITRO through `JuMP`_, a domain-specific modeling language for mathematical programming embedded in Julia.

Re-visiting the `example`_, here's what it'll look like with JuMP:

.. code-block:: julia

  using KNITRO, JuMP
  m = Model(solver=KnitroSolver(options_file="knitro.opt"))
  @defVar(m, x[1:3]>=0)
  @setNLObjective(m, Min, 9.0 - 8.0*x[1] - 6.0*x[2] - 4.0*x[3]
                          + 2.0*x[1]^2 + 2.0*x[2]^2 + x[3]^2
                          + 2.0*x[1]*x[2] + 2.0*x[1]*x[3])
  @addConstraint(m, x[1] + x[2] + 2.0*x[3] <= 3)
  solve(m)

Solver Parameters
^^^^^^^^^^^^^^^^^
You can also provide `solver parameters`_ to KNITRO in JuMP, e.g.

.. code-block:: julia

  KnitroSolver() # default parameters
  KnitroSolver(KTR_PARAM_ALG=5)
  KnitroSolver(hessopt=1)

You can also provide the path to the options, or tuner, using the ``options_file`` or ``tuner_file`` keywords respectively, e.g.

.. code-block:: julia

  KnitroSolver(options_file="tuner-fixed.opt")
  KnitroSolver(tuner_file="tuner-explore.opt")

.. _JuMP: http://jump.readthedocs.org/en/latest/
.. _example: http://knitrojl.readthedocs.org/en/latest/example.html
.. _solver parameters: http://knitrojl.readthedocs.org/en/latest/solverparams.html