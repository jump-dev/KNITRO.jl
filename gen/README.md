# Generate C wrapper for Knitro

This is a subproject, using Clang.jl to generate automatically
a wrapper for Knitro.

To install the project locally and download Clang.jl:
```shell
julia --project -e "using Pkg ; Pkg.instantiate()"
```

Once the project installed, you can regenerate the C wrapper directly with:
```julia
using Clang
include("generate_wrapper.jl")

```
This takes as input the header file `knitro.h` in the `KNITRODIR`
directory and generates automatically all the Julia bindings with Clang.jl.

