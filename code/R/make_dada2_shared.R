library(tidyverse)

data_in <- read_tsv("./data/dada2/asv_table.tsv")

data_out <- data_in %>%
  rename(Group=sampleID) %>%
  mutate(label="dada2",numOtus=ncol(data_in)-1) %>%
  select(label,Group,numOtus,everything())

write_tsv(data_out,"./data/dada2/asv_table.shared")
