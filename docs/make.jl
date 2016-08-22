using Documenter, KNITRO

# Pkg.add("DataFrames")
# Pkg.add("TypedTables")
# using DataFrames
# using NamedTuples
# using TypedTables

makedocs(
    modules = [KNITRO]
)

deploydocs(
    deps = Deps.pip("pygments", "mkdocs", "mkdocs-material", "python-markdown-math"),
    repo = "github.com/JuliaOpt/KNITRO.jl.git",
    julia = "0.4"
)