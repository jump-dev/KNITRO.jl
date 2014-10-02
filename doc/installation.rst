Installation Guide
------------------
Knitro isn't a listed package (yet). Here's what you need to do to install it

1. First, you must obtain a copy of the KNITRO software and a license; trial versions and academic licenses are available `here`_.

2. Once KNITRO is installed on your machine (in your home directory), point the ``PATH`` and ``DYLD_LIBRARY_PATH`` variable to the KNITRO library by adding 

.. code-block:: bash

    export PATH="$HOME/knitro-9.0.1-z/knitroampl:$PATH"
    export DYLD_LIBRARY_PATH="$HOME/knitro-9.0.1-z/lib:$DYLD_LIBRARY_PATH"

to your start-up file (e.g. ``.bash_profile``).

3. At the Julia prompt, run 

.. code-block:: julia

    julia> Pkg.clone("https://github.com/yeesian/Knitro.jl.git")

(or manually clone this module to your `.julia` directory).

4. Copy the dynamic libraries from ``$HOME/knitro-<version-number>/lib`` to ``$(Pkg.dir())/Knitro.jl/deps/usr/lib``.

5. Test that KNITRO works by runnning

.. code-block:: julia
    
    julia> Pkg.test("Knitro.jl")


.. _here: http://www-01.ibm.com/software/websphere/products/optimization/cplex-studio-preview-edition/