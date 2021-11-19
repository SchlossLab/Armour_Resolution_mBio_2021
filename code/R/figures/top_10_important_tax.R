library(tidyverse)
library(glue)
library(ggtext)
library(cowplot)

### FUNCTIONS ########

read_rf_imp <- function(tax_level){
  read_csv(paste0("data/process/importance-",tax_level,"-rf.csv"),
           col_types = c(perf_metric = col_double(),
                         perf_metric_diff = col_double(),
                         seed = col_double(),
                         .default = col_character())) %>%
    mutate(level=tax_level)
}

read_tax <- function(tax_level){
  read_tsv(paste0("data/",tax_level,"/crc.taxonomy"),
           col_types = c(Size = col_double(),
                         .default = col_character())) %>%
    mutate(level=tax_level)
}

rank_tax <- function(data,tax){
  sub_data <- data %>%
    filter(level==tax) %>%
    group_by(level,Taxonomy,OTU) %>%
    summarise(mean_AUC_diff = median(AUC_diff)) %>%
    ungroup() %>%
    arrange(desc(mean_AUC_diff)) %>%
    mutate(rank=seq(1,nrow(.)))

  return(sub_data)
}

plot_top_imp <- function(top_data,tax_level){
  if(tax_level == "Phylum"){
    top_data %>%
      filter(level == tax_level) %>%
      arrange(rank) %>%
      ggplot(aes(x=AUC_diff,y=reorder(name,desc(rank)))) +
      stat_summary(fun.data=median_hilow, fun.args=0.5, geom="pointrange", color=colors2[tax_level]) +
      # stat_summary(fun = mean,geom = "pointrange",  color=colors2[tax_level],
      #              fun.max = function(x) mean(x) + sd(x),
      #              fun.min = function(x) mean(x) - sd(x)) +
      scale_x_continuous(breaks=seq(-0.02,0.04,0.02)) +
      theme_bw() +
      theme(axis.title.y = element_blank(),
            axis.text.y = element_markdown(),
            plot.caption = element_markdown(lineheight = 1.2)) +
      ggtitle(tax_level) +
      xlab("Decrease in AUROC")
  }else{
    top_data %>%
      filter(level == tax_level) %>%
      arrange(rank) %>%
      ggplot(aes(x=AUC_diff,y=reorder(name,desc(rank)))) +
      stat_summary(fun.data=median_hilow, fun.args=0.5, geom="pointrange", color=colors2[tax_level]) +
      # stat_summary(fun = mean,geom = "pointrange",  color=colors2[tax_level],
      #              fun.max = function(x) mean(x) + sd(x),
      #              fun.min = function(x) mean(x) - sd(x)) +
      scale_x_continuous(breaks=seq(0,0.04,0.01)) +
      theme_bw() +
      theme(axis.title.y = element_blank(),
            axis.text.y = element_markdown(),
            plot.caption = element_markdown(lineheight = 1.2)) +
      ggtitle(tax_level) +
      xlab("Decrease in AUROC")
  }
}

### VARIABLES ########

levels <- c("phylum","class","order","family","genus","otu","asv")
levels_names <- c("Phylum","Class","Order","Family","Genus","OTU","ASV")

colors <- c("#D04C44","#E7834E","#E6A444","#829E88","#83BCC3","#7989A4","#B29ABA")
names(colors) <- levels

colors2 <- colors
names(colors2) <- levels_names

### MAIN ########
rf_imp <- map_dfr(levels,read_rf_imp)

rf_tax <- map_dfr(levels,read_tax)

rf_imp_tax <- rf_imp %>%
  select(perf_metric,perf_metric_diff,names,method,seed,level) %>%
  rename(AUC=perf_metric,OTU=names,AUC_diff=perf_metric_diff) %>%
  inner_join(rf_tax,by=c("level","OTU"))


ranked_tax <- map_dfr(levels,rank_tax,data=rf_imp_tax)

top_10_tax <- ranked_tax %>%
  filter(rank <= 10)

top_10_data <- inner_join(rf_imp_tax,top_10_tax,by=c("level","OTU","Taxonomy")) %>%
  mutate(level = factor(level,levels=levels,labels=levels_names)) %>%
  select(level,seed,OTU,Taxonomy,AUC_diff,rank) %>%
  mutate(Taxonomy=case_when(level=="OTU" ~ sapply(strsplit(Taxonomy,"();"), `[`, 6),
                            level=="ASV" ~ sapply(strsplit(Taxonomy,"();"), `[`, 6),
                            TRUE ~ Taxonomy)) %>%
  mutate(Taxonomy=sapply(strsplit(Taxonomy,"\\("), `[`, 1)) %>%
  mutate(name = str_replace(Taxonomy,"(.*)","*\\1*")) %>%
  mutate(name = str_replace(name,"\\*(.*)_unclassified\\*","Unclassified *\\1*")) %>%
  mutate(name = sub("_","\\?",name)) %>%
  mutate(name = str_replace(name,"\\*(.*)\\?(.*)\\*","\\*\\1\\* \\2")) %>%
  mutate(name = gsub("\\?"," ",name)) %>%
  mutate(name = gsub("_"," ",name)) %>%
  mutate(OTUname = str_replace(OTU,"Otu0*([0-9]*)","OTU \\1")) %>%
  mutate(name = gsub(" $","",name)) %>%
  mutate(name = glue("{name}({OTUname})"))

plotlist <- map(levels_names,plot_top_imp,top_data=top_10_data)

plot_grid(plotlist = plotlist,ncol = 2,align = "v")
ggsave("analysis/figures/top_10_important_tax.tiff",
       scale=1.25,
       height = 9,width = 6.87,units="in",
       compression = "lzw")
