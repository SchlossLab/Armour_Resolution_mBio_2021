#generate a plot comparing the sensitivity at 90% sensitivity_at_90_specificity

library(tidyverse)

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

sens_spec90 %>%
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
ggsave("analysis/figures/sensitivity_at_90_specificity.png",width = 4.5,height=5,units="in")
