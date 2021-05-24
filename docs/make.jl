using Documenter
using PotreeConverter

# makedocs(
# 	format = Documenter.HTML(),
# 	sitename = "OrthographicProjection.jl",
# 	#assets = ["assets/OrthographicProjection.css", "assets/logo.jpg"],
# 	modules = [OrthographicProjection]
# )
#
#
# deploydocs(
# 	repo = "github.com/marteresagh/OrthographicProjection.jl.git"
# )


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
