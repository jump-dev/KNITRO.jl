using Documenter, KNITRO

makedocs(
    modules = [KNITRO]
)

deploydocs(
    deps = Deps.pip("pygments", "mkdocs", "mkdocs-material", "python-markdown-math"),
    repo = "github.com/JuliaOpt/KNITRO.jl.git",
    julia = "0.4"
)