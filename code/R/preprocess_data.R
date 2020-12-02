library(docopt)
library(mikropml)
library(tidyverse)
library(data.table)

'mikropml preprocess data

Usage:
  preprocess_data.R --data=<csv> --taxonomy=<level>
  preprocess_data.R (-h | --help)

Options:
  -h --help           Show this screen.
  --data=<csv>        Input data in csv format.
  --taxonomy=<level>  taxonomic level.

' -> doc

args <- docopt(doc)

print(R.version$version.string) 

outdir <- paste0("./data/",args$taxonomy,"/")

data <- as_tibble(fread(args$data))

# for ASV level data, filter out columns with count 1 
# these will be removed anyway in preprocessing
# so this speeds up the processing for large data
if( args$taxonomy == "asv" ){
	data <- data[,colSums(data != 0) > 1]
}

data_proc <- mikropml::preprocess_data(data, 'dx')$dat_transformed

write_csv(data_proc,paste0("./data/",args$taxonomy,"/input_data_preproc.csv"))
