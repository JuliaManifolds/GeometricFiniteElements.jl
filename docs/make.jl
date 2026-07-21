#!/usr/bin/env julia
#
#

if "--help" ∈ ARGS
    println(
        """
        docs/make.jl

        Render the `GeometricFiniteElements.jl` documentation with optional arguments

        Arguments
        * `--help`              - print this help and exit without rendering the documentation
        * `--prettyurls`        – toggle the pretty urls part to true, which is always set on CI
        """
    )
    exit(0)
end
run_on_CI = (get(ENV, "CI", nothing) == "true")

#
# if docs is not the current active environment, switch to it
# (from https://github.com/JuliaIO/HDF5.jl/pull/1020/) 
if Base.active_project() != joinpath(@__DIR__, "Project.toml")
    using Pkg
    Pkg.activate(@__DIR__)
    Pkg.instantiate()
end

# (c) load necessary packages for the docs
using Documenter
using DocumenterCitations, DocumenterInterLinks
using GeometricFiniteElements

# (d) add contributing.md and changelog.md to the docs – and link to releases and issues

function add_links(line::String, url::String = "https://github.com/JuliaManifolds/Manopt.jl")
    # replace issues (#XXXX) -> ([#XXXX](url/issue/XXXX))
    while (m = match(r"\(\#([0-9]+)\)", line)) !== nothing
        id = m.captures[1]
        line = replace(line, m.match => "([#$id]($url/issues/$id))")
    end
    # replace ## [X.Y.Z] -> with a link to the release [X.Y.Z](url/releases/tag/vX.Y.Z)
    while (m = match(r"\#\# \[([0-9]+.[0-9]+.[0-9]+)\] (.*)", line)) !== nothing
        tag = m.captures[1]
        date = m.captures[2]
        line = replace(line, m.match => "## [$tag]($url/releases/tag/v$tag) ($date)")
    end
    return line
end

generated_path = joinpath(@__DIR__, "src")
base_url = "https://github.com/JuliaManifolds/Manopt.jl/blob/master/"
isdir(generated_path) || mkdir(generated_path)
for (md_file, doc_file) in
    [
        #   ("CONTRIBUTING.md", "contributing.md"),
        ("Changelog.md", "changelog.md"),
    ]
    open(joinpath(generated_path, doc_file), "w") do io
        # Point to source license file
        println(
            io,
            """
            ```@meta
            EditURL = "$(base_url)$(md_file)"
            ```
            """,
        )
        # Write the contents out below the meta block
        for line in eachline(joinpath(dirname(@__DIR__), md_file))
            println(io, add_links(line))
        end
    end
end

## Build tutorials menu
# (e) finally make docs
bib = CitationBibliography(joinpath(@__DIR__, "src", "references.bib"); style = :alpha)
links = InterLinks(
    "ManifoldsBase" => ("https://juliamanifolds.github.io/ManifoldsBase.jl/stable/"),
    "Manifolds" => ("https://juliamanifolds.github.io/Manifolds.jl/stable/"),
)
makedocs(;
    format = Documenter.HTML(;
        prettyurls = run_on_CI || ("--prettyurls" ∈ ARGS),
        # assets = ["assets/favicon.ico", "assets/citations.css", "assets/link-icons.css"],
    ),
    modules = [
        GeometricFiniteElements,
    ],
    authors = "Ronny Bergmann <git@ronnybergmann.net>, Anton Schiela <anton.schiela@uni-bayreuth.de>, Laura Weigl <laura.weigl@uni-bayreuth.de>",
    sitename = "GeometricFiniteElements.jl",
    pages = [
        "Home" => "index.md",
        "Changelog" => "changelog.md",
        "References" => "references.md",
    ],
    plugins = [bib, links],
)
deploydocs(; repo = "github.com/JuliaManifolds/GeometricFiniteElements.jl", push_preview = true)
#back to main env
Pkg.activate()
