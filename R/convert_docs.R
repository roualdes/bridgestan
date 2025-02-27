# Converts R documentation (.Rd) files to markdown (.md) files
# for use in Sphinx.

library(rd2markdown)
library(roxygen2)

roxygen2::roxygenize()

files <- list.files("man", pattern="*.Rd")

# we only want to doc exported functions, so we need
# to read the NAMESPACE file
namespace <- paste0(readLines("NAMESPACE"), collapse="\n")

for (f in files){
    name <- substr(f, 1, nchar(f)-3)

    if (!grepl(name, namespace, fixed=TRUE)){
        print(paste0("Skipping unexported ", name))
        next
    }

    # read .Rd file and convert to markdown
    rd <- rd2markdown::get_rd(file=file.path(".", "man", f))
    md <- rd2markdown::rd2markdown(rd, fragments=c(), level=3)

    # write it to the docs folder
    writeLines(md, file.path("..", "docs", "languages", "_r", paste0(name, ".md")))

}
