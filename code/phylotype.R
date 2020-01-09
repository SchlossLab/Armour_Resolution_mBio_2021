library(tidyverse)


input <- commandArgs(trailingOnly=TRUE) # recieve input from model
# Get variables from command line
level <- input[1]

path <- "data/phylotype/"
if(!dir.exists(path)){
	dir.create(path)
}

shared_file <- 'data/mothur/crc.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.0.03.subsample.shared'

otu_tax_file <- 'data/mothur/crc.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.0.03.cons_rdp.taxonomy'

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

pooled <- inner_join(shared, taxonomy, by="OTU") %>%
	group_by(Group, taxon) %>%
	summarize(count = sum(count)) %>%
	ungroup() %>%
	spread(taxon, count) %>%
	mutate(label=level, numOtus=ncol(.)-1) %>%
	select(label, Group, numOtus, everything())

write_tsv(pooled, paste0(path, "crc.", level, ".shared"))

n_taxa <- ncol(pooled) - 3

tibble(OTU=paste0("Otu", str_pad(1:n_taxa, str_length(n_taxa), pad=0)),
		Size=select(pooled, -label, -numOtus) %>% gather(tax, count, -Group) %>% group_by(tax) %>% summarize(count=sum(count)) %>% pull(count),
			Taxonomy=colnames(pooled)[-c(1,2,3)]
	) %>%
	write_tsv(paste0(path, "crc.", level, ".taxonomy"))
