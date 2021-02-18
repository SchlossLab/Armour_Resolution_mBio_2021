library(tidyverse)
library(data.table)

levels <- c("phylum","class","order","family","genus","otu","asv")

input <- NULL

for(l in levels){
  in_data <- as.data.frame(fread(paste0("./data/",l,"/input_data.csv")))
  in_data_preproc <- as.data.frame(fread(paste0("./data/",l,"/input_data_preproc.csv")))

  n_samp <- nrow(in_data)
  n_feat <- ncol(in_data) - 1
  n_feat_preproc <- ncol(in_data_preproc) - 1

  input <- input %>%
    bind_rows(c(level=l,n_samples=n_samp,n_features=n_feat,n_features_preproc=n_feat_preproc))
}

write_csv(input,"./analysis/input_values.csv")
