library(tidyverse)

#functions adapted from begum mbio paper
read_files <- function(filenames){
  for(file in filenames){
    # Read the files generated in main.R
    # These files have cvAUCs and testAUCs for 100 data-splits
    data <- read.delim(file, header=T, sep=',') %>%
      mutate(level=unlist(strsplit(file,"-"))[2])

  }
  return(data)
}

hp_files <- list.files(path= 'data/process', pattern='hp-.*-.*.csv', full.names = TRUE)
hp.df <- map_df(hp_files, read_files)

hp.df %>% 
  group_by(mtry,level) %>%
  summarise("mean_AUC" = mean(AUC),
            "sd_AUC" = sd(AUC),
            # is there a less repetitive way to do this cleanly?
            ymin_metric = mean_AUC - sd_AUC,
            ymax_metric = mean_AUC + sd_AUC) %>% 
  mutate(level=factor(level,levels=c("phylum","class","order","family","genus","otu","asv"),
                      labels=c("Phylum","Class","Order","Family","Genus","OTU","ASV"))) %>% 
  ggplot(aes(x=mtry,y=mean_AUC)) +
  geom_point(size=2,alpha=0.5) + geom_line(alpha=0.5) +
  facet_grid(.~level,scales = "free_x") +
  theme_bw() +
  geom_errorbar(aes(
    ymin = .data$ymin_metric,
    ymax = .data$ymax_metric),
    width = .001)

ggsave("analysis/hp-rf.png")
