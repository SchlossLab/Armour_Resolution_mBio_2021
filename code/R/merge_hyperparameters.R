library(docopt)
library(tidyverse)

'Merge hyperparameter data.

Usage:
  merge_hyperparameters.R --level=<level> --method=<method>
  merge_hyperparameters.R (-h | --help)

Options
  -h --help 	     Display this message.
  --method=<method>  Model name, options
			rf
			glmnet
			svmRadial
			rpart2
			xgbTree
  --level=<level>    Taxonomic level.

' -> doc

args <- docopt(doc)

level <- args$level
method <- args$method

#function from Begum mBio 2020 paper
read_files <- function(filenames){
  for(file in filenames){
    data <- read.delim(file, header=T, sep=',') %>%
	mutate(seed=unlist(strsplit(file,"\\."))[3])
  }
  return(data)
}

#read in all the importance files for the 100 seeds
files <- list.files(path=paste0("./data/",level,"/temp/"),pattern=paste0("hp_",method,".*"),full.names=TRUE)

#build the merged dataframe
hp <- map_df(files, read_files) %>%
   mutate(level=level)

outfile <- paste0("./data/process/hp-",level,"-",method,".csv")
write_csv(hp,outfile)
