library(docopt)
library(tidyverse)

'Merge importance data.

Usage:
  merge_importance.R --level=<level> --method=<method> --threshold=<threshold>
  merge_importance.R (-h | --help)

Options
  -h --help                Display this message.
  --method=<method>        Model name, options
			rf
			glmnet
			svmRadial
			rpart2
			xgbTree
  --level=<level>          Taxonomic level.
  --threshold=<threshold>  Importance threshold.

' -> doc

args <- docopt(doc)

level <- args$level
method <- args$method
threshold <- args$thresh

#function from Begum mBio 2020 paper
read_files <- function(filenames){
  for(file in filenames){
    data <- read.delim(file, header=T, sep=',')
  }
  return(data)
}

if(threshold == 1){
  #read in all the importance files for the 100 seeds
  files <- list.files(path=paste0("./data/",level,"/temp/"),pattern=paste0("importance_",method,".*"),full.names=TRUE)

  #build the merged dataframe
  importance <- map_df(files, read_files) %>%
     mutate(level=level)

  outfile <- paste0("./data/process/importance-",level,"-",method,".csv")

}else{
  #read in all the importance files for the 100 seeds
  files <- list.files(path=paste0("./data/",level,"/temp/"),pattern=paste0("importance_",method,".*"),full.names=TRUE)

  #build the merged dataframe
  importance <- map_df(files, read_files) %>%
     mutate(level=level)

  outfile <- paste0("./data/process/importance",threshold,"-",level,"-",method,".csv")

}

write_csv(importance,outfile)
