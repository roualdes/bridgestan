using Documenter, BridgeStan
using DocumenterMarkdown

makedocs(format=Markdown())

cp(joinpath(@__DIR__, "build/julia.md"), joinpath(@__DIR__, "../../python/docs/languages/julia.md"); force=true)
cp(joinpath(@__DIR__, "build/assets/Documenter.css"), joinpath(@__DIR__, "../../python/docs/_static/css/Documenter.css"); force=true)
