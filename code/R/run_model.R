starttime=Sys.time()

library(docopt)
library(mikropml)
library(tidyverse)

'Run mikRopML pipeline.

Usage:
  run_model.R --data=<csv> --method=<name> --seed=<num> --taxonomy=<level> --outcome_colname=<colname> --outcome_value=<value> --hyperparams=<csv>
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
  --hyperparams=<csv>          csv with hyperparameter values.

' -> doc

args <- docopt(doc)

outdir <- paste0("./data/",args$taxonomy,"/temp/")
if( !dir.exists(outdir) ){
        dir.create(outdir,recursive=T)
}

# read in preprocessed data
data_proc <- read_csv(args$data)

# get hyperparamter values for model/taxonomy
hp <- read_csv(args$hyperparams)
sub_hp <- hp %>% 
	filter(model == args$method, level == args$taxonomy)

# create list of hyperparams
new_hp <- list()
params <- unique(sub_hp$param)
for(i in 1:length(params)){
	p <- params[i]  
	new_hp[[p]] <- sub_hp %>% 
		filter(param == p) %>% 
		pull(number)    
}

model <- mikropml::run_ml(dataset = data_proc,
                          method = args$method,
                          outcome_colname = args$outcome_colname, 
                          seed = as.numeric(as.character(args$seed)),
			  find_feature_importance=TRUE,
			  hyperparameters = new_hp )

feature_importance <- model$feature_importance
write_csv(feature_importance,paste0(outdir,"importance_",args$method,".",args$seed,".csv"))

hyperparameters <- get_hp_performance(model$trained_model)$dat
write_csv(hyperparameters,paste0(outdir,"hp_",args$method,".",args$seed,".csv"))

performance <- model$performance
results <- performance

outfile <- paste0(outdir,args$method,".",args$seed,".csv")
write_csv(results,outfile)

endtime=Sys.time()
print(paste0(args$taxonomy,": ",round(difftime(endtime,starttime,units="secs"),digits=2)," seconds"))
