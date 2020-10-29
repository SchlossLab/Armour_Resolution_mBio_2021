library(docopt)
library(mikropml)
library(tidyverse)

'Run mikRopML pipeline.

Usage:
  run_model.R --data=<csv> --method=<name> --seed=<num> --taxonomy=<level> --outcome_colname=<colname> --outcome_value=<value>
  run_model.R (-h | --help)

Options
  -h --help                    Display this help message.
  --data=<csv>                 input data in csv format.
  --method=<name>              model name. options:
                                 rf
                                 regLogistic
                                 svmRadial
                                 rpart2
                                 xgbTree
  --seed=<num>                 random seed.
  --taxonomy=<level>           taxonomic level.
  --outcome_colname=<colname>  colname in data for outcome variable.
  --outcome_value=<value>      value of interest in outcome column.

' -> doc

args <- docopt(doc)

outdir <- paste0("./data/",args$taxonomy,"/temp/")
if( !dir.exists(outdir) ){
        dir.create(outdir,recursive=T)
}

data_proc <- read_csv(paste0("./data/",args$taxonomy,"/input_data_preproc.csv"))

model <- mikropml::run_ml(dataset = data_proc,
                          method = args$method,
                          outcome_colname = args$outcome_colname, 
                          outcome_value = args$outcome_value,
                          seed = as.numeric(as.character(args$seed)) )
model

hyperparameters <- get_hp_performance(model$trained_model)$dat
write.csv(hyperparameters) <- paste0(outdir,"hp_",args$method,".",args$seed,".csv")

performance <- model$performance
results <- performance[,c("cv_auroc","test_auroc","method")]

outfile <- paste0(outdir,args$method,".",args$seed,".csv")
write.csv(results,outfile,row.names=F,quote=F)

