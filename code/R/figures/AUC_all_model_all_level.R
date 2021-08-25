library(tidyverse)
library(nationalparkcolors)

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

### MAIN ########

# Generate dataframe of all results and tables of the median cv and test AUCs
full_df <- NULL
auc_df <- NULL

for( m in models ){
  model_df <- map_dfr(levels, read_combined, model = m)

  full_df <- bind_rows(full_df,model_df)
}

# adjust table
df_all <- full_df %>%
  select(cv_metric_AUC,AUC,method,level) %>%
  rename(test_AUC=AUC,cv_AUC=cv_metric_AUC) %>%
  pivot_longer(cols=c("cv_AUC","test_AUC"),names_to="auc_type",values_to="AUC") %>%
  mutate(level=factor(level,levels=c("phylum","class","order","family","genus","otu","asv"),
                      labels=c("Phylum","Class","Order","Family","Genus","OTU","ASV")),
         method=factor(method,levels=c("rf","glmnet","xgbTree","svmRadial","rpart2"),
                       labels=c("Random Forest","Logistic Regression","XGBoost","SVM Radial","Decision Tree")))

#plot results
df_all %>%
  filter(auc_type == "test_AUC") %>%
  ggplot(aes(x=level,y=AUC,fill=method)) +
  geom_hline(yintercept = 0.5,color="grey",lty="dashed") +
  geom_boxplot(alpha=0.9) +
  theme_bw() + xlab("") + ylab("AUROC") +
  theme(legend.position ="top",
        axis.text.x = element_text(angle = 0),
        axis.text = element_text(size=14)) +
  scale_fill_manual(values=pal2,name="Model")
ggsave("analysis/figures/AUC_all_model_all_level.png",width = 7,height=4,units="in")
