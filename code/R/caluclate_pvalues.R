library(tidyverse)
library(mosaic)

#models <- c("rf","glmnet","xgbTree","svmRadial","rpart2")
models <- c("rf","glmnet","rpart2")
levels <- c("phylum","class","order","family","genus","otu","asv")

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

#compare two models levels within a taxonomic level
perm_p_value_level <- function(data, model_name_1, model_name_2, level_name){
  test_subsample <- data %>%
    select(AUC,method,level) %>%
    filter((method == model_name_1 | method == model_name_2) & level == level_name)
  obs <- abs(diff(mosaic::mean(AUC ~ method, data = test_subsample)))
  auc.null <- do(10000) * diff(mosaic::mean(AUC ~ shuffle(method), data = test_subsample))
  n <- length(auc.null[,1])
  # r = #replications at least as extreme as observed effect
  r <- sum(abs(auc.null[,1]) >= obs)
  # compute Monte Carlo p-value with correction (Davison & Hinkley, 1997)
  p.value=(r+1)/(n+1)
  return(p.value)
}

#compare two taxonomic levels within a model type
perm_p_value_model <- function(data, model_name, level_name_1, level_name_2){
  test_subsample <- data %>%
    select(AUC,method,level) %>%
    filter(method == model_name & ( level == level_name_1 | level == level_name_2))
  obs <- abs(diff(mosaic::mean(AUC ~ level, data = test_subsample)))
  auc.null <- do(10000) * diff(mosaic::mean(AUC ~ shuffle(level), data = test_subsample))
  n <- length(auc.null[,1])
  # r = #replications at least as extreme as observed effect
  r <- sum(abs(auc.null[,1]) >= obs)
  # compute Monte Carlo p-value with correction (Davison & Hinkley, 1997)
  p.value=(r+1)/(n+1)
  #plot <- ggplot(auc.null, aes(x=auc.null[,1], color=auc.null[,1]>=obs)) + geom_histogram(fill="white", alpha=0.5, position="identity") +
  #  scale_color_brewer(palette="Dark2") + geom_vline(xintercept = obs,color="grey",lty="dashed")
  return(p.value)
}

all_files <- list.files(path= './data/process', pattern='combined-.*', full.names = TRUE)

all.df <- map_df(all_files, read_files)

#perm_p_value_model(all.df, "rf", "genus", "otu")
#perm_p_value_level(all.df, "rpart2","rf","genus")

p.table.level <- NULL
p.table.level <- expand_grid(x=1:length(levels),
                             y=1:length(models),
                             z=1:length(models)) %>%
  filter(y < z) %>%
  mutate(level = levels[x], model1 = models[y], model2 = models[z]) %>%
  select(-x, -y, -z) %>%
  group_by(level, model1, model2) %>%
  summarize(p_value = perm_p_value_level(all.df,model1,model2,level),
            .groups="drop")
write.csv(p.table.level,"./analysis/pvalues_by_level.csv",row.names = F,quote = F)

p.table.model <- NULL
p.table.model <- expand_grid(x=1:length(levels),
                             y=1:length(levels),
                             z=1:length(models)) %>%
  filter(x < y) %>%
  mutate(level1 = levels[x], level2 = levels[y], model = models[z]) %>%
  select(-x, -y, -z) %>%
  group_by(model, level1, level2) %>%
  summarize(p_value = perm_p_value_model(all.df,model,level1,level2),
            .groups="drop")
write.csv(p.table.model,"./analysis/pvalues_by_model.csv",row.names = F,quote = F)

detach("package:mosaic", unload=TRUE)
