# This script takes the taxonomic level as an argument and merges the senspec files
# for each seed into one file in the data/process directory

library(tidyverse)

args=commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
  stop("Taxonomic level must be supplied")
}

tax_level = args[1]

levels = c("phylum","class","order","family","genus","otu","asv")
if( !(tax_level %in% levels) ){
  stop(c(paste0("unrecognized taxonomic level: ",tax_level,"\n"),
      "recognized levels: ",paste0(levels,collasep=" ")))
}

read_files <- function(filenames){
  for(file in filenames){
    data <- read.delim(file, header=T, sep=',')
  }
  return(data)
}

files <- list.files(path=paste0("./data/",tax_level,"/temp/"),pattern=paste0("senspec_rf.*"),full.names=TRUE)

senspec <- map_df(files, read_files) %>%
   mutate(level=tax_level)

outfile <- paste0("./data/process/senspec-",tax_level,"-rf.csv")
write_csv(senspec,outfile)
