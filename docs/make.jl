using Documenter, KNITRO

makedocs(
    modules = [KNITRO]
)

deploydocs(
    deps = Deps.pip("pygments", "mkdocs", "mkdocs-material", "python-markdown-math"),
    repo = "github.com/jump-dev/KNITRO.jl.git",
    julia = "0.4"
)