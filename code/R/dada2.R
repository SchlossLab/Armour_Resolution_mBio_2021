library(dada2)
library(tidyverse)
library(phyloseq)
library(Biostrings)

# set output directory location and create if needed
outpath <- "./data/dada2/"
if(!dir.exists(outpath)){dir.create(outpath)}

# Forward and reverse fastq filenames have format: SAMPLENAME_1.fastq and SAMPLENAME_2.fastq
fnFs <- sort(list.files("data/raw/merged/", pattern="_1.fastq", full.names = TRUE))
fnRs <- sort(list.files("data/raw/merged/", pattern="_2.fastq", full.names = TRUE))

# Extract sample names, assuming filenames have format: SAMPLENAME_XXX.fastq
sample.names <- sapply(strsplit(basename(fnFs), "_"), `[`, 1)

# Place filtered files in filtered/ subdirectory
filtFs <- file.path("data/raw/merged/", "filtered", paste0(sample.names, "_F_filt.fastq.gz"))
filtRs <- file.path("data/raw/merged/", "filtered", paste0(sample.names, "_R_filt.fastq.gz"))
names(filtFs) <- sample.names
names(filtRs) <- sample.names

out <- filterAndTrim(fnFs, filtFs, fnRs, filtRs, truncLen=c(240,160),
              maxN=0, maxEE=c(2,2), truncQ=2, rm.phix=TRUE,
              compress=TRUE, multithread=TRUE)
saveRDS(out,paste0(outpath,"filter_trim.rds"))

# learn error rates
errF <- learnErrors(filtFs, multithread=TRUE)
errR <- learnErrors(filtRs, multithread=TRUE)

png(paste0(outpath,"errorsF.png"))
plotErrors(errF, nominalQ=TRUE)
dev.off()

png(paste0(outpath,"errorsR.png"))
plotErrors(errR, nominalQ=TRUE)
dev.off()

# sample inference
dadaFs <- dada(filtFs, err=errF, multithread=TRUE)
dadaRs <- dada(filtRs, err=errR, multithread=TRUE)

print("Inspecting the returned dada-class object:")
dadaFs[[1]]
dadaRs[[1]]

# merge paired reads
mergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs, verbose=TRUE)
# Inspect the merger data.frame from the first sample
head(mergers[[1]])

# construct sequence table
seqtab <- makeSequenceTable(mergers)
dim(seqtab)

table(nchar(getSequences(seqtab)))

#remove chimeras
seqtab.nochim <- removeBimeraDenovo(seqtab, method="consensus", multithread=TRUE, verbose=TRUE)
dim(seqtab.nochim)
sum(seqtab.nochim)/sum(seqtab)

saveRDS(seqtab.nochim,paste0(outpath,"seqtab_nochim.rds"))

#track reads through pipeline
getN <- function(x) sum(getUniques(x))
track <- cbind(out, sapply(dadaFs, getN), sapply(dadaRs, getN), sapply(mergers, getN), rowSums(seqtab.nochim))
# If processing a single sample, remove the sapply calls: e.g. replace sapply(dadaFs, getN) with getN(dadaFs)
colnames(track) <- c("input", "filtered", "denoisedF", "denoisedR", "merged", "nonchim")
rownames(track) <- sample.names
head(track)

saveRDS(track,paste0(outpath,"track_reads.rds"))

# Assign taxonomy
taxa <- assignTaxonomy(seqtab.nochim, "data/dada2/silva_nr_v132_train_set.fa.gz", multithread=TRUE)
taxa <- addSpecies(taxa, "data/dada2/silva_species_assignment_v132.fa.gz")

taxa.print <- taxa # Removing sequence rownames for display only
rownames(taxa.print) <- NULL
head(taxa.print)

saveRDS(taxa,paste0(outpath,"taxonomy.rds"))

### get ASV table
metadata <- read_csv("./data/metadata/metadata.csv") %>%
	column_to_rownames(var="sample")

ps <- phyloseq(otu_table(seqtab.nochim, taxa_are_rows=FALSE),
               #sample_data(metadata),
               tax_table(taxa))

dna <- Biostrings::DNAStringSet(taxa_names(ps))
names(dna) <- taxa_names(ps)
ps <- merge_phyloseq(ps, dna)
taxa_names(ps) <- paste0("ASV", seq(ntaxa(ps)))
ps

# Extract abundance matrix from the phyloseq object
OTU1 = as(otu_table(ps), "matrix")
# transpose if necessary
if(taxa_are_rows(ps)){OTU1 <- t(OTU1)}
# Coerce to data.frame
OTUdf = as.data.frame(OTU1)

saveRDS(OTUdf,paste0(outpath,"asv_table.rds"))
write_tsv(OTUdf %>% rownames_to_column(var="sampleID"),paste0(outpath,"asv_table.tsv"))
