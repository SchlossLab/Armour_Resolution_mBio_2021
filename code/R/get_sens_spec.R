library(tidyverse)

### FUNCTIONS ############################

get_file_list <- function(tax_level){
  list.files(path=paste0("data/",tax_level,"/temp/data"),
             pattern="rf_model.*.Rdata",
             full.names=T)
}

get_sensitivity <- function(lookup, x){
  if(x >= max(lookup$specificity)){
    tibble(specificity=x,sensitivity=0)
  } else {
    lookup %>%
      filter(specificity - x > 0) %>%
      top_n(sensitivity, n=1) %>%
      summarize(specificity=x,
                sensitivity = unique(sensitivity))
  }
}

pool_sens_spec <- function(file_name,specificities){
  load(file_name)

  prob <- predict(model$trained_model, model$test_data, type="prob")

  prob_obs <- bind_cols(prob_srn = prob$cancer,
                        observed=model$test_data$dx)

  total <- count(prob_obs, observed) %>%
    pivot_wider(names_from="observed", values_from="n")

  lookup <- prob_obs %>%
    arrange(desc(prob_srn)) %>%
    mutate(is_srn = observed == "cancer") %>%
    mutate(tp = cumsum(is_srn),
           fp = cumsum(!is_srn),
           sensitivity = tp / total$cancer,
           fpr = fp / total$normal) %>%
    mutate(specificity = 1- fpr) %>%
    select(sensitivity, specificity, fpr)

  map_dfr(specificities,get_sensitivity,lookup=lookup) %>%
    mutate(model = str_replace(file_name,
                               "data/(.*)/temp/data/rf_model.\\d*.Rdata", "\\1"),
           seed = str_replace(file_name,
                              "data/(.*)/temp/data/rf_model.(\\d*).Rdata", "\\2"))
}

loop_sens_spec <- function(tax_level,specificities){
  get_file_list(tax_level) %>%
    map_dfr(pool_sens_spec,specificities)
}

### VARIABLES ###########################

levels <- c("phylum","class","order","family","genus","otu","asv")
specificities <- seq(0, 1, 0.01)

### MAIN ################################

map_dfr(levels,loop_sens_spec,specificities) %>%
  write_csv("analysis/sens_spec_by_level.csv")
