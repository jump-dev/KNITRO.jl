------------------
Installation Guide
------------------
1. First, you must obtain a copy of the Artelys Knitro software and a license; trial versions and academic licenses are available `here`_.

2. Once Artelys Knitro is installed on your machine, point the ``LD_LIBRARY_PATH`` (Linux) or ``DYLD_LIBRARY_PATH`` (OS X) variable to the Artelys Knitro library by adding, e.g.,

.. code-block:: bash

    export LD_LIBRARY_PATH="$HOME/knitro-9.0.1-z/lib:$LD_LIBRARY_PATH"

or

.. code-block:: bash

    export DYLD_LIBRARY_PATH="$HOME/knitro-9.0.1-z/lib:$DYLD_LIBRARY_PATH"

to your start-up file (e.g. ``.bash_profile``).

3. At the Julia prompt, run 

.. code-block:: julia

    julia> Pkg.add("KNITRO")

4. Test that KNITRO.jl works by runnning

.. code-block:: julia
    
    julia> Pkg.test("KNITRO")

Setting up Knitro on Windows
^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Note that currently *only 64-bit* Windows is supported. That is, you must use 64-bit Julia and install the Win64 version of Artelys Knitro.

1. First, you must obtain a copy of the Artelys Knitro software and a license; trial versions and academic licenses are available `here`_.

2. Once Artelys Knitro is installed on your machine, add the directory containing ``knitro.dll`` to the `PATH` environment variable, as described in the Artelys Knitro documentation. 

3. At the Julia prompt, run

.. code-block:: julia

    julia> Pkg.add("KNITRO")

4. Test that KNITRO.jl works by runnning

.. code-block:: julia
    
    julia> Pkg.test("KNITRO")


.. _here: https://www.artelys.com/en/optimization-tools/knitro#downloads-tab