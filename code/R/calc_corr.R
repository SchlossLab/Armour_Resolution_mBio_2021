starttime=Sys.time()
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(data.table))

##### Arguments and checks #####################
args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
  stop("Taxonomic level must be supplied")
}

tax_level = args[1]

levels = c("phylum","class","order","family","genus","otu","asv")
if( !(tax_level %in% levels) ){
  stop(c(paste0("unrecognized taxonomic level: ",tax_level,"\n"),
      "recognized levels: ",paste0(levels,collasep=" ")))
}

##### Data files #####################
in_file <- paste0("./data/",tax_level,"/input_data.csv")
in_proc_file <- paste0("./data/",tax_level,"/input_data_preproc.csv")

message("Reading in data...")

input_data <- as.data.frame(fread(in_file))
input_data_preproc <- as.data.frame(fread(in_proc_file))

##### Correlations #####################
message("calculating correlations...")

calculate_corr <- function(data,item1,item2){
  item1_vals <- data %>%
    pull(`item1`)
  item2_vals <- data %>%
    pull(`item2`)

  return(cor(item1_vals,item2_vals,method="pearson"))
}

n_taxa <- ncol(input_data_preproc) - 1

keep_names <- input_data_preproc %>%
  select(-dx) %>%
  colnames()

# unprocessed
sub_input_data <- input_data %>%
  select(all_of(keep_names))

input_corr <- expand_grid(x=1:length(keep_names),
                          y=1:length(keep_names)) %>%
  filter(x < y) %>%
  mutate(taxa1 = keep_names[x], taxa2 = keep_names[y]) %>%
  select(-x, -y) %>%
  group_by(taxa1,taxa2) %>%
  summarise(corr = calculate_corr(sub_input_data,taxa1,taxa2)) %>%
  mutate(level = tax_level) %>%
  ungroup()

# processed
sub_input_data_preproc <- input_data_preproc %>%
  select(all_of(keep_names))

input_proc_corr <- expand_grid(x=1:length(keep_names),
                          y=1:length(keep_names)) %>%
  filter(x < y) %>%
  mutate(taxa1 = keep_names[x], taxa2 = keep_names[y]) %>%
  select(-x, -y) %>%
  group_by(taxa1,taxa2) %>%
  summarise(proc_corr = calculate_corr(sub_input_data_preproc,taxa1,taxa2)) %>%
  mutate(level = tax_level) %>%
  ungroup()

##### Write output #####################
message("writing output...")
#merge
output <- inner_join(input_corr,input_proc_corr,by=c("taxa1","taxa2","level")) %>%
  select(level,taxa1,taxa2,corr,proc_corr)

write_csv(output,paste0("./analysis/taxa_correlations_",tax_level,".csv"))

message("done!")
endtime=Sys.time()
print(paste0(tax_level,": ",round(difftime(endtime,starttime,units="secs"),digits=2)," seconds"))
