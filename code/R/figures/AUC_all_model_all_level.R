library(tidyverse)

### FUNCTIONS ########
read_combined <- function(tax_level,model){
  read_csv(paste0("data/process/combined-",tax_level,"-",model,".csv"),
           col_types = c(method = col_character(),.default=col_double()),
           na = c("","NA","NaN")) %>% #some of the Pos/Neg Pred Values were NaN
    mutate(level=tax_level) 
}

### VARIABLES ########
models <- c("rf","glmnet","xgbTree","svmRadial","rpart2")
levels <- c("phylum","class","order","family","genus","otu","asv")
levels_names <- c("Phylum","Class","Order","Family","Genus","OTU","ASV")
pal <- park_palette("Everglades",length(models))
names(pal) <- models
pal2 <- park_palette("Everglades",length(models))
names(pal2) <- c("Random Forest","Logistic Regression","XGBoost","SVM Radial","Decision Tree")

# Generate dataframe of all results and tables of the median cv and test AUCs
full_df <- NULL
auc_df <- NULL



for( m in models ){
  model_df <- map_dfr(levels, read_combined, model = m)
  
  full_df <- bind_rows(full_df,model_df)
  
  m_auc.df <- select(model_df,cv_metric_AUC,AUC,method,level) %>% 
    rename(test_AUC=AUC) %>% 
    pivot_longer(cols = c("cv_metric_AUC","test_AUC"),names_to="auc_type",values_to="AUC")
  
  m_auc.df$level <- factor(m_auc.df$level,levels=c("phylum","class","order","family","genus","otu","asv"))
  
  auc_df <- bind_rows(auc_df,m_auc.df)
  
  cv_med <- m_auc.df %>%
    filter(auc_type == "cv_metric_AUC") %>%
    group_by(level) %>% 
    summarise(!!m := median(AUC),.groups = 'drop') 
  
  t_med <- m_auc.df %>% 
    filter(auc_type == "test_AUC") %>%
    group_by(level) %>% 
    summarise(!!m := median(AUC),.groups = 'drop') 
  
  cv_table <- inner_join(cv_table,cv_med,by="level")
  t_table <- inner_join(t_table,t_med,by="level")
}

write_csv(t_table,"./figures/median_test_auc.csv")

#compare two models levels within a taxonomic level
p.table.level <- read_csv("../analysis/pvalues_by_level.csv",
                          col_types = c(p_value = col_double(),.default=col_character()))
#compare two taxonomic levels within a model type
p.table.model <- read_csv("../analysis/pvalues_by_model.csv",
                          col_types = c(p_value = col_double(),.default=col_character()))

df_all <- full_df %>% 
  select(cv_metric_AUC,AUC,method,level) %>% 
  rename(test_AUC=AUC,cv_AUC=cv_metric_AUC) %>% 
  pivot_longer(cols=c("cv_AUC","test_AUC"),names_to="auc_type",values_to="AUC") %>% 
  mutate(level=factor(level,levels=c("phylum","class","order","family","genus","otu","asv"),
                      labels=c("Phylum","Class","Order","Family","Genus","OTU","ASV")),
         method=factor(method,levels=c("rf","glmnet","xgbTree","svmRadial","rpart2"),
                       labels=c("Random Forest","Logistic Regression","XGBoost","SVM Radial","Decision Tree")))

df_all %>% 
  filter(auc_type == "test_AUC") %>% 
  ggplot(aes(x=level,y=AUC,fill=method)) + 
  geom_hline(yintercept = 0.5,color="grey",lty="dashed") +
  geom_boxplot(alpha=0.9) + 
  theme_bw() + xlab("") + ylab("AUROC") + 
  theme(legend.position ="top",
        axis.text.x = element_text(angle = 0),
        axis.text = element_text(size=14)) +
  scale_fill_manual(values=pal2,name="Model") #+
#guides(fill=guide_legend(nrow=2))
ggsave("./figures/all_model_level.png",width = 7,height=4,units="in")