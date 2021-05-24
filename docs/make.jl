using Documenter
using PotreeConverter

makedocs(
    modules = [PotreeConverter],
    format = Documenter.HTML(
        prettyurls = "deploy" in ARGS,
    ),
    sitename = "PotreeConverter.jl",
    pages = [
        "Home" => "index.md",
        "References" => "refs.md",
    ]
)

deploydocs(
    repo = "github.com/marteresagh/PotreeConverter.jl.git",
    push_preview = true,
    devurl = "dev",
)
