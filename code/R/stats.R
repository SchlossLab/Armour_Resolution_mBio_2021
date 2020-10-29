library(tidyverse)
library(mosaic)
library(reshape2)

#functions adapted from Begum mbio paper
read_files <- function(filenames){
  for(file in filenames){
    # Read the files generated in main.R
    # These files have cvAUCs and testAUCs for 100 data-splits
    data <- read.delim(file, header=T, sep=',') %>%
      mutate(level=unlist(strsplit(file,"-"))[2])
    
  }
  return(data)
}

#compare two models levels within a taxonomic level
perm_p_value <- function(data, model_name_1, model_name_2, level_name){
  test_subsample <- data %>%
    select(-cv_auroc) %>%
    filter((method == model_name_1 | method == model_name_2) & level == level_name)
  obs <- abs(diff(mosaic::mean(test_auroc ~ method, data = test_subsample)))
  auc.null <- do(10000) * diff(mosaic::mean(test_auroc ~ shuffle(method), data = test_subsample))
  n <- length(auc.null[,1])
  # r = #replications at least as extreme as observed effect
  r <- sum(abs(auc.null[,1]) >= obs)
  # compute Monte Carlo p-value with correction (Davison & Hinkley, 1997)
  p.value=(r+1)/(n+1)
  #plot <- ggplot(auc.null, aes(x=auc.null[,1], color=auc.null[,1]>=obs)) + geom_histogram(fill="white", alpha=0.5, position="identity") + 
  #  scale_color_brewer(palette="Dark2") + geom_vline(xintercept = obs,color="grey",lty="dashed")
  return(p.value)
}

#compare two taxonomic levels within a model type
perm_p_value_model <- function(data, model_name, level_name_1, level_name_2){
  test_subsample <- data %>%
    select(-cv_auroc) %>%
    filter(method == model_name & ( level == level_name_1 | level == level_name_2))
  obs <- abs(diff(mosaic::mean(test_auroc ~ level, data = test_subsample)))
  auc.null <- do(10000) * diff(mosaic::mean(test_auroc ~ shuffle(level), data = test_subsample))
  n <- length(auc.null[,1])
  # r = #replications at least as extreme as observed effect
  r <- sum(abs(auc.null[,1]) >= obs)
  # compute Monte Carlo p-value with correction (Davison & Hinkley, 1997)
  p.value=(r+1)/(n+1)
  #plot <- ggplot(auc.null, aes(x=auc.null[,1], color=auc.null[,1]>=obs)) + geom_histogram(fill="white", alpha=0.5, position="identity") + 
  #  scale_color_brewer(palette="Dark2") + geom_vline(xintercept = obs,color="grey",lty="dashed")
  return(p.value)
}

files <- list.files(path= 'data/process', pattern='combined-.*', full.names = TRUE)
all <- map_df(files, read_files) 

p.table <- NULL
for(l in levels){
  for(i in 1:(length(models)-1) ){
    for(j in i:length(models)){
        if(i==j){
          next
        }
        model1  <- models[i]
        model2  <- models[j]

        pval <- perm_p_value(all,model1,model2,l)

        p.table <- rbind(p.table,c(model1,model2,l,pval))
    }
  }
}
colnames(p.table) <- c("model1","model2","level","pvalue")
write.csv(p.table,"./data/analysis/pvalues_by_level.csv",row.names = F,quote = F)
p.table_level <- read_csv("./data/analysis/pvalues_by_level.csv")

p.table_model <- NULL
for(m in models){
  for(i in 1:(length(levels)-1) ){
    for(j in i:length(levels)){
        if(i==j){
          next
        }
        level1  <- levels[i]
        level2  <- levels[j]

        pval <- perm_p_value_model(all,m,level1,level2)

        p.table_model <- rbind(p.table_model,c(m,level1,level2,pval))
    }
  }
}
colnames(p.table_model) <- c("model","level1","level2","pvalue")
write.csv(p.table_model,"./data/analysis/pvalues_by_model.csv",row.names = F,quote = F)
p.table_model <- read_csv("./data/analysis/pvalues_by_model.csv")

detach("package:mosaic", unload=TRUE)
