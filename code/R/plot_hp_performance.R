library(tidyverse)
library(docopt)
library(cowplot)

'plot hp performance

Usage:
  plot_hp_performance.R --method=<str>

Options:
  --method=<str>  model name. options:
                   rf
                   regLogistic
                   svmRadial
                   rpart2
		   xgbTree

' -> doc

args <- docopt(doc)

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

hp_files <- list.files(path= 'data/process', pattern=paste0('hp-.*-',args$method,'.csv'), full.names = TRUE)
hp.df <- map_df(hp_files, read_files)

if(args$method == "svmRadial"){
  param1 <- colnames(hp.df)[1]
  param2 <- colnames(hp.df)[2]


  p1 <- hp.df %>%
    rename(param1 := !!param1, param2 := !!param2) %>%
    mutate(param1 = as.factor(param1)) %>%
    group_by(param1,param2,level) %>%
    summarise("mean_AUC" = mean(AUC),
              "sd_AUC" = sd(AUC),
              # is there a less repetitive way to do this cleanly?
              ymin_metric = mean_AUC - sd_AUC,
              ymax_metric = mean_AUC + sd_AUC) %>%
    mutate(level=factor(level,levels=c("phylum","class","order","family","genus","otu","asv"),
                        labels=c("Phylum","Class","Order","Family","Genus","OTU","ASV"))) %>%
    ggplot(aes(x=param2,y=mean_AUC,color=param1)) +
    geom_point(size=2,alpha=0.5) + geom_line(alpha=0.5) +
    facet_grid(.~level,scales = "free_x") +
    theme_bw() +
    xlab(param2) +
    scale_x_continuous(trans='log10')
    geom_errorbar(aes(
      ymin = .data$ymin_metric,
      ymax = .data$ymax_metric),
      width = .001)

  p2 <- hp.df %>%
    rename(param1 := !!param1, param2 := !!param2) %>%
    mutate(param2 = as.factor(param2)) %>%
    group_by(param1,param2,level) %>%
    summarise("mean_AUC" = mean(AUC),
              "sd_AUC" = sd(AUC),
              # is there a less repetitive way to do this cleanly?
              ymin_metric = mean_AUC - sd_AUC,
              ymax_metric = mean_AUC + sd_AUC) %>%
    mutate(level=factor(level,levels=c("phylum","class","order","family","genus","otu","asv"),
                        labels=c("Phylum","Class","Order","Family","Genus","OTU","ASV"))) %>%
    ggplot(aes(x=param1,y=mean_AUC,color=param2)) +
    geom_point(size=2,alpha=0.5) + geom_line(alpha=0.5) +
    facet_grid(.~level,scales = "free_x") +
    theme_bw() +
    xlab(param1) +
    scale_x_continuous(trans='log10')
    geom_errorbar(aes(
      ymin = .data$ymin_metric,
      ymax = .data$ymax_metric),
      width = .001)

  plot_grid(p1,p2)
  ggsave(paste0("analysis/hp-",args$method,".png"),height=4,width=10)

}
if(args$method == "glmnet"){
  hp.df <- hp.df %>%
    select(-alpha)

  param <- colnames(hp.df)[1]

  hp.df %>%
    rename(param := !!param) %>%
    group_by(param,level) %>%
    summarise("mean_AUC" = mean(AUC),
              "sd_AUC" = sd(AUC),
              # is there a less repetitive way to do this cleanly?
              ymin_metric = mean_AUC - sd_AUC,
              ymax_metric = mean_AUC + sd_AUC) %>%
    mutate(level=factor(level,levels=c("phylum","class","order","family","genus","otu","asv"),
                        labels=c("Phylum","Class","Order","Family","Genus","OTU","ASV"))) %>%
    ggplot(aes(x=param,y=mean_AUC)) +
    geom_point(size=2,alpha=0.5) + geom_line(alpha=0.5) +
    facet_grid(.~level,scales = "free_x") +
    theme_bw() +
    xlab(param) +
    scale_x_continuous(trans='log10') +
    geom_errorbar(aes(
      ymin = .data$ymin_metric,
      ymax = .data$ymax_metric),
      width = .001)
  ggsave(paste0("analysis/hp-",args$method,".png"),height=4,width=7)
}else{

  param <- colnames(hp.df)[1]

  hp.df %>%
    rename(param := !!param) %>%
    group_by(param,level) %>%
    summarise("mean_AUC" = mean(AUC),
              "sd_AUC" = sd(AUC),
              # is there a less repetitive way to do this cleanly?
              ymin_metric = mean_AUC - sd_AUC,
              ymax_metric = mean_AUC + sd_AUC) %>%
    mutate(level=factor(level,levels=c("phylum","class","order","family","genus","otu","asv"),
                        labels=c("Phylum","Class","Order","Family","Genus","OTU","ASV"))) %>%
    ggplot(aes(x=param,y=mean_AUC)) +
    geom_point(size=2,alpha=0.5) + geom_line(alpha=0.5) +
    facet_grid(.~level,scales = "free_x") +
    theme_bw() +
    xlab(param) +
    geom_errorbar(aes(
      ymin = .data$ymin_metric,
      ymax = .data$ymax_metric),
      width = .001)
  ggsave(paste0("analysis/hp-",args$method,".png"),height=4,width=7)
}
