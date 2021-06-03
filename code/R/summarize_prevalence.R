# This script reads in the input data and preprocessed input data for
# each taxonomic level and quantifies the prevalence of each taxa
# as the number of samples with count > 1 / number of samples
# outputs overall prevalence values and per group (SRN vs normal) prev

library(tidyverse)
library(data.table)

#function to read input files and calculate prevalence
get_prevalence_preprocess <- function(file,file_proc,level){
  data <- as.data.frame(fread(file))
  data_proc <- as.data.frame(fread(file_proc))
  if(nrow(data) != nrow(data_proc)){
    stop("Why is there a different number of samples in preprocessed data!")
  }
  n_samp <- nrow(data)
  keep_names <- str_replace(colnames(data_proc)[-1],"_1","")
  total_prev <- data %>%
    select(-dx) %>%
    #select(data,keep_names) %>% #only keep taxa in preprocessed data
    pivot_longer(everything(),names_to="name",values_to="count") %>%
    filter(count > 0) %>%
    group_by(name) %>%
    tally() %>%
    mutate(total_prevalence=n/n_samp) %>%
    mutate(level := !!level) %>%
    select(level,name,total_prevalence) %>%
    mutate(kept=case_when(name %in% keep_names ~ 1,
                          TRUE ~ 0))

  n_srn <- data %>% select(dx) %>% filter(dx=="cancer") %>% tally() %>% pull()
  n_norm <- data %>% select(dx) %>% filter(dx=="normal") %>% tally() %>% pull()
  if(n_srn + n_norm != n_samp){
    stop("why doesn't n_srn + n_normal = n_sample?")
  }
  div_prev <- data %>%
    pivot_longer(starts_with("Otu"),names_to="name",values_to="count") %>%
    filter(count > 0) %>%
    group_by(name,dx) %>%
    tally() %>%
    pivot_wider(id_cols = name,names_from = dx,values_from = n,values_fill = 0) %>%
    mutate(srn_prevalence=cancer/n_srn,
           normal_prevalence=normal/n_norm) %>%
    select(name,srn_prevalence,normal_prevalence)

  prev <- total_prev %>%
    inner_join(div_prev,by="name") %>%
    select(level,name,srn_prevalence,normal_prevalence,total_prevalence,kept)

  return(prev)
}

prev_df <- get_prevalence_preprocess("./data/phylum/input_data.csv",
                                     "./data/phylum/input_data_preproc.csv",
                                     "phylum") %>%
  bind_rows(get_prevalence_preprocess("./data/class/input_data.csv",
                                      "./data/class/input_data_preproc.csv",
                                      "class")) %>%
  bind_rows(get_prevalence_preprocess("./data/order/input_data.csv",
                                      "./data/order/input_data_preproc.csv",
                                      "order")) %>%
  bind_rows(get_prevalence_preprocess("./data/family/input_data.csv",
                                      "./data/family/input_data_preproc.csv",
                                      "family")) %>%
  bind_rows(get_prevalence_preprocess("./data/genus/input_data.csv",
                                      "./data/genus/input_data_preproc.csv",
                                      "genus")) %>%
  bind_rows(get_prevalence_preprocess("./data/otu/input_data.csv",
                                      "./data/otu/input_data_preproc.csv",
                                      "otu")) %>%
  bind_rows(get_prevalence_preprocess("./data/asv/input_data.csv",
                                      "./data/asv/input_data_preproc.csv",
                                      "asv"))
write_csv(prev_df,"./analysis/prevalence_by_level.csv")
