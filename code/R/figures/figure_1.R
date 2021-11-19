# library(png)
# library(grid)
# library(gridExtra)
# library(tidyverse)

# img1 <-  rasterGrob(as.raster(readPNG("analysis/figures/rf_AUC_all_level.png")), interpolate = FALSE)
# img2 <-  rasterGrob(as.raster(readPNG("analysis/figures/sensitivity_at_90_specificity.png")), interpolate = FALSE)
# g <- grid.arrange(arrangeGrob(img1, left = textGrob("A", x = unit(1, "npc"), y = unit(0.95, "npc"), gp = gpar(fontface="bold"))),
#              arrangeGrob(img2, left = textGrob("B", x = unit(1, "npc"), y = unit(0.95, "npc"), gp = gpar(fontface="bold"))),
#              ncol = 2)
# # g <- arrangeGrob(arrangeGrob(img1, left = textGrob("A", x = unit(1.2, "npc"), y = unit(0.95, "npc"), gp = gpar(fontface="bold"))),
# #             arrangeGrob(img2, left = textGrob("B", x = unit(1, "npc"), y = unit(0.95, "npc"), gp = gpar(fontface="bold"))),
# #             ncol = 2)
# ggsave(filename = "paper/figure_1.tiff",
#        plot = g,
#        height=3,width=6.87,units="in")

library(tidyverse)
library(cowplot)

#############################
### rf_AUC_all_level plot ###
#############################

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
plot1 <- rf_auc_df %>%
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

#####################################
### sensitivity_at_90_specificity ###
#####################################

### VARIABLES #####################
levels <- c("phylum","class","order","family","genus","otu","asv")
levels_names <- c("Phylum","Class","Order","Family","Genus","OTU","ASV")
colors <- c("#D04C44","#E7834E","#E6A444","#829E88","#83BCC3","#7989A4","#B29ABA")
names(colors) <- levels

colors2 <- colors
names(colors2) <- levels_names

sens_spec90 <- read_csv("analysis/sens_spec_by_level.csv") %>%
  filter(specificity == 0.9) %>%
  mutate(level = factor(level,levels=rev(levels),labels=rev(levels_names)))

### PLOTS #####################

#check stats
stats <- read_csv("analysis/sens_spec90_pvals.csv") %>%
  filter(p_value >= 0.05)
if( nrow(stats) != 4){ stop("problem with stats)")}

plot2 <- sens_spec90 %>%
  ggplot(aes(x=level,y=sensitivity,color=level)) +
    geom_jitter(width=0.2,alpha=0.5,size=2,height = 0) +
    #stat_summary(fun.data=median_hilow, fun.args=0.5, geom="pointrange", color="black") +
    stat_summary(fun = mean,
                 fun.max = function(x) mean(x) + sd(x),
                 fun.min = function(x) mean(x) - sd(x),
                 #geom = "crossbar", width=0.6,
                 geom = "pointrange",
                 color="black") +
    theme_bw() +
    xlab("") + ylab("Sensitivity") +
    theme(axis.text = element_text(size=12),
          axis.title = element_text(size=12),
          legend.position = "none",
          panel.grid.major.y = element_blank()) +
    coord_flip() +
    scale_y_continuous(breaks=seq(0,1,0.1),labels = scales::percent_format(accuracy = 1)) +
    scale_color_manual(values=rev(colors2)) +
    annotate("text",x=levels_names,y=rep((max(sens_spec90$sensitivity)+0.05),length(levels_names)),label=c("W","W","X","Y","Y","Y","Z"))
    
p <- plot_grid(plot1,plot2,nrow=1,labels=c("A","B"),label_size = 14)

ggsave(filename = "paper/figure_1.tiff",
       plot = p,scale=1.5,
       height=3,width=6,units="in")
