library(tidyverse)


input <- commandArgs(trailingOnly=TRUE) # recieve input from model
# Get variables from command line
level <- input[1]

path <- paste0("data/", level, "/")

if(!dir.exists(path)){
	dir.create(path)
}

shared_file <- 'data/otu/crc.shared'
otu_tax_file <- 'data/otu/crc.taxonomy'

shared <- read_tsv(shared_file, col_type=cols(Group=col_character())) %>%
	select(-label, -numOtus) %>%
	gather(-Group, key=OTU, value=count)

taxonomy <- read_tsv(otu_tax_file) %>%
	select(-Size) %>%
	mutate(Taxonomy=str_replace_all(Taxonomy, "\\(\\d*\\)", "")) %>%
	mutate(Taxonomy=str_replace_all(Taxonomy, ";$", "")) %>%
	separate(Taxonomy, c("kingdom", "phylum", "class", "order", "family", "genus"), sep=';') %>%
	select(OTU, level) %>%
	rename(taxon = level)

unique_taxonomy <- taxonomy %>%
	select(taxon) %>%
	unique() %>%
	mutate(otu = paste0("Otu", str_pad(1:nrow(.), width=nchar(nrow(.)), pad="0")))


pooled <- inner_join(shared, taxonomy, by="OTU") %>%
	group_by(taxon, Group) %>%
	summarize(count = sum(count)) %>%
	ungroup() %>%
	inner_join(., unique_taxonomy) %>%
	select(-taxon) %>%
	spread(otu, count) %>%
	mutate(label=level, numOtus=ncol(.)-1) %>%
	select(label, Group, numOtus, everything())

write_tsv(pooled, paste0(path, "crc.shared"))


select(pooled, -label, -numOtus) %>%
	gather(otu, count, -Group) %>%
	group_by(otu) %>%
	summarize(count=sum(count)) %>%
	inner_join(., unique_taxonomy) %>%
	rename("OTU"="otu", "Size"="count", "Taxonomy"="taxon") %>%
	write_tsv(paste0(path, "crc.taxonomy"))
