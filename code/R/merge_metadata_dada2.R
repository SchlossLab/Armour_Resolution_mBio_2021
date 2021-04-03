library(tidyverse)

metadata <- read.delim('./data/metadata/metadata.csv', header=T, sep=',') %>% select(sample,Dx_Bin,fit_result)

shared <- read.delim("./data/dada2/asv_table.dada2.subsample.shared", header=T, sep='\t')

data<- inner_join(metadata,shared,by=c("sample"="Group")) %>%
  mutate(dx=case_when(
    Dx_Bin =="Adenoma" ~ "normal",
    Dx_Bin== "Normal" ~ "normal",
    Dx_Bin== "High Risk Normal" ~ "normal",
    Dx_Bin== "adv Adenoma" ~ "cancer",
    Dx_Bin== "Cancer" ~ "cancer"
  )) %>%
  select(-sample,-label,-numOtus,-Dx_Bin,-fit_result) %>%
  drop_na() %>%
  select(dx,everything()) %>%
  write_csv("data/dada2/input_data.csv")
