library(tidyverse)
library(dplyr)
library(Hmisc)
library(RcmdrMisc)
library(here)
#setwd("~/GitHub/schloss_projects/XXXXX_Resolution_XXXX_2020")
metadata <- read.delim('./data/metadata/metadata.csv', header=T, sep=',') %>% select(sample,Dx_Bin,fit_result)

input <- commandArgs(trailingOnly=TRUE) # recieve input from model
level <- input[1]

shared <- read.delim(paste0("./data/",level,"/crc.shared"), header=T, sep='\t') %>% select(-label,-numOtus)

data<- inner_join(metadata,shared,by=c("sample"="Group")) %>% 
  mutate(dx=case_when(
    Dx_Bin =="Adenoma" ~ "normal",
    Dx_Bin== "Normal" ~ "normal",
    Dx_Bin== "High Risk Normal" ~ "normal",
    Dx_Bin== "adv Adenoma" ~ "cancer",
    Dx_Bin== "Cancer" ~ "cancer"
  )) %>% 
  select(-sample,-Dx_Bin,-fit_result) %>% 
  drop_na() %>% 
  select(dx,everything()) %>% 
  write_csv(paste0("data/",level,"/input_data.csv"))
