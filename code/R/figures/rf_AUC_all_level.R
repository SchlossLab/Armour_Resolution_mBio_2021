library(tidyverse)

### FUNCTIONS ########
read_combined <- function(tax_level,model){
  read_csv(paste0("data/process/combined-",tax_level,"-",model,".csv"),
           col_types = c(method = col_character(),.default=col_double()),
           na = c("","NA","NaN")) %>% #some of the Pos/Neg Pred Values were NaN
    mutate(level=tax_level)
}

### VARIABLES ########

levels <- c("phylum","class","order","family","genus","otu","asv")
levels_names <- c("Phylum","Class","Order","Family","Genus","OTU","ASV")

colors <- c("#D04C44","#E7834E","#E6A444","#829E88","#83BCC3","#7989A4","#B29ABA")
names(colors) <- levels

colors2 <- colors
names(colors2) <- levels_names

### MAIN ########

rf_auc_df <- map_dfr(levels, read_combined, model = "rf") %>%
  select(cv_metric_AUC,AUC,method,level) %>%
  rename(test_AUC=AUC) %>%
  pivot_longer(cols = c("cv_metric_AUC","test_AUC"),names_to="auc_type",values_to="AUC") %>%
  mutate(level=factor(level,levels=c("phylum","class","order","family","genus","otu","asv"),
                      labels=c("Phylum","Class","Order","Family","Genus","OTU","ASV"))) %>%
  filter(auc_type=="test_AUC")

#compare two taxonomic levels within a model type
rf_stats <- read_csv("analysis/pvalues_by_model.csv",
                          col_types = c(p_value = col_double(),.default=col_character())) %>%
  mutate(level1=factor(level1,levels=c("phylum","class","order","family","genus","otu","asv"),
                       labels=c("Phylum","Class","Order","Family","Genus","OTU","ASV")),
         level2=factor(level2,levels=c("phylum","class","order","family","genus","otu","asv"),
                       labels=c("Phylum","Class","Order","Family","Genus","OTU","ASV"))) %>%
  filter(model == "rf") %>%
  select(-model) %>%
  filter(p_value > 0.05)
if( nrow(rf_stats) != 5){ stop("problem with stats)")}

# create plot
rf_auc_df %>%
  ggplot(aes(x=factor(level,levels=c("ASV", "OTU","Genus","Family","Order","Class", "Phylum")),y=AUC)) +
    geom_jitter(aes(fill=level,color=level),height = 0, width = 0.25,shape=21,size=2) +
    stat_summary(fun = mean,
                 fun.max = function(x) mean(x) + sd(x),
                 fun.min = function(x) mean(x) - sd(x),
                 #geom = "crossbar", width=0.6,
                 geom = "pointrange",
                 color="black") +
    scale_fill_manual(values = alpha(colors2,0.5)) +
    scale_color_manual(values = colors2) +
    scale_y_continuous(limits=c(0.45,0.87),breaks = seq(0.5,0.8,0.1),expand=c(0,0)) +
    theme_bw() + xlab("") + ylab("AUROC") +
    theme(legend.position ="none",
          #axis.text.x = element_text(angle = 45,hjust = 1),
          panel.grid.major.y = element_blank(),
          axis.text = element_text(size=12),
          axis.title = element_text(size=12)) +
    coord_flip() +
    annotate("text",x=levels_names,y=rep(0.85,length(levels_names)),label=c("A","B","C","D,E","D,E","D","E")) +
    geom_hline(yintercept = 0.5,color="grey",lty="dashed")

ggsave("analysis/figures/rf_AUC_all_level.png",
       width = 4.5,height=5)
