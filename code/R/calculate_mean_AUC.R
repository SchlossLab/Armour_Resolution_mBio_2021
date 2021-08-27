library(tidyverse)

### FUNCTIONS #####################
read_combined <- function(tax_level,model){
  read_csv(paste0("data/process/combined-",tax_level,"-",model,".csv"),
           col_types = c(method = col_character(),.default=col_double()),
           na = c("","NA","NaN")) %>% #some of the Pos/Neg Pred Values were NaN
    mutate(level=tax_level)
}

### VARIABLES #####################
models <- c("rf","glmnet","xgbTree","svmRadial","rpart2")
levels <- c("phylum","class","order","family","genus","otu","asv")

mean_table <- tibble(level=levels)

for( m in models ){
  model_df <- map_dfr(levels, read_combined, model = m)

  m_auc.df <- select(model_df,cv_metric_AUC,AUC,method,level) %>%
    rename(test_AUC=AUC) %>%
    pivot_longer(cols = c("cv_metric_AUC","test_AUC"),names_to="auc_type",values_to="AUC") %>%
    mutate(level = factor(level, levels=levels))

  AUC_mean <- m_auc.df %>%
    filter(auc_type == "test_AUC") %>%
    group_by(level) %>%
    summarise(!!m := mean(AUC),.groups = 'drop')

  mean_table <- inner_join(mean_table,AUC_mean,by="level")
}

write_csv(mean_table,"analysis/mean_AUC_by_model.csv")
