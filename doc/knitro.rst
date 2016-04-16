===========================================================
KNITRO.jl --- Julia interface for the Artelys Knitro solver
===========================================================

.. module:: KNITRO.jl
   :synopsis: Julia interface for the Artelys Knitro solver

The KNITRO.jl package provides an interface for using the `Artelys Knitro solver`_ from the `Julia language`_. You cannot use KNITRO.jl without having purchased and installed a copy of Artelys Knitro from `Artelys`_. This package is available free of charge and in no way replaces or alters any functionality of the Artelys Knitro solver.

Artelys Knitro functionality is extensive, so KNITRO.jl's coverage is incomplete, but the basic functionality for solving linear, nonlinear, and mixed-integer programs is provided.

Contents
--------
.. toctree::
   :maxdepth: 2

   installation.rst
   example.rst
   solving.rst
   solverparams.rst
   callbacks.rst
   jumpinterface.rst

.. _Artelys Knitro solver: http://www.ziena.com/knitro.htm
.. _Julia language: http://julialang.org/
.. _Artelys: https://www.artelys.com/