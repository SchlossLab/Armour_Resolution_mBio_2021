library(reshape2)
library(ggplot2)
library(RColorBrewer)



plot_model_auc <- function(model){
  class <- read.csv(paste0("data/process/combined_class_best_hp_results_",model,".csv"), header=TRUE)
  family <- read.csv(paste0("data/process/combined_family_best_hp_results_",model,".csv"), header=TRUE)
  genus <- read.csv(paste0("data/process/combined_genus_best_hp_results_",model,".csv"), header=TRUE)
  order <- read.csv(paste0("data/process/combined_order_best_hp_results_",model,".csv"), header=TRUE)
  phylum <- read.csv(paste0("data/process/combined_phylum_best_hp_results_",model,".csv"), header=TRUE)
  otu <- read.csv(paste0("data/process/combined_otu_best_hp_results_",model,".csv"), header=TRUE)
  asv <- read.csv(paste0("data/process/combined_asv_best_hp_results_",model,".csv"), header=TRUE)
  
  labels <- c("auc","phylum","class","order","family","genus","otu","asv")
  cv_aucs <- data.frame(matrix(ncol=8, nrow=100))
  colnames(cv_aucs) <- labels
  cv_aucs$auc <- rep("Cross-validation",100)
  cv_aucs$phylum <- phylum$cv_aucs
  cv_aucs$class <- class$cv_aucs
  cv_aucs$order <- order$cv_aucs
  cv_aucs$family <- family$cv_aucs
  cv_aucs$genus <- genus$cv_aucs
  cv_aucs$otu <- otu$cv_aucs
  cv_aucs$asv <- asv$cv_aucs
  
  test_aucs <- data.frame(matrix(ncol=8, nrow=100))
  colnames(test_aucs) <- labels
  test_aucs$auc <- rep("Testing AUC",100)
  test_aucs$phylum <- phylum$test_aucs
  test_aucs$class <- class$test_aucs
  test_aucs$order <- order$test_aucs
  test_aucs$family <- family$test_aucs
  test_aucs$genus <- genus$test_aucs
  test_aucs$otu <- otu$test_aucs
  test_aucs$asv <- asv$test_aucs
  
  auc <- rbind(test_aucs,cv_aucs)
  m.df <- melt(auc, id.var="auc")
  colnames(m.df) <- c("AUC_category","Taxonomy","AUC_value")
  m.df$AUC_category <- as.factor(m.df$AUC_category)
  
  
  model_plot<-ggplot(m.df, aes(x=Taxonomy, y=AUC_value, fill=AUC_category)) +
    geom_boxplot(notch=TRUE) + 
    theme_bw() + 
    theme(legend.position ="bottom") + 
    scale_x_discrete(name= "Taxonomy") + 
    scale_y_continuous(name="AUC") + 
    scale_fill_brewer(palette="Accent") +
    ggtitle(model) + labs(fill=" ")
  ggsave(paste0("figures/auc_",model,".png"), model_plot)

}

args<- commandArgs(trailingOnly = TRUE)
model <- args[1]
plot_model_auc(model)




# parser<- OptionParser()
# parser <-add_option(parser, c("--model"), action = "store_true", help= "Model options:
#                   L2_Logistic_Regression
#                   L1_Linear_SVM
#                   L2_Linear_SVM
#                   RBF_SVM
#                   Random_Forest
#                   XGBoost
#                   Decision_Tree")



