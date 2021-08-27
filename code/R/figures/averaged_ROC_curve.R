library(tidyverse)

### VARIABLES #####################
levels <- c("phylum","class","order","family","genus","otu","asv")
levels_names <- c("Phylum","Class","Order","Family","Genus","OTU","ASV")
colors <- c("#D04C44","#E7834E","#E6A444","#829E88","#83BCC3","#7989A4","#B29ABA")
names(colors) <- levels

colors2 <- colors
names(colors2) <- levels_names

sens_spec <- read_csv("analysis/sens_spec_by_level.csv")

### PLOTS #####################

# calculate average/sd sensitivity
avg_sens <- sens_spec %>%
  group_by(specificity,level) %>%
  summarise(mean_sensitivity = mean(sensitivity),
            sd_sensitivity = sd(sensitivity),
            .groups = "drop") %>%
  mutate(upper_sens = mean_sensitivity + sd_sensitivity,
         lower_sens = mean_sensitivity - sd_sensitivity) %>%
  mutate(level=factor(level,levels=levels,labels=levels_names)) %>%
  mutate(upper_sens = case_when(upper_sens > 1 ~ 1,
                                TRUE ~ upper_sens),
         lower_sens = case_when(upper_sens < 0 ~ 0,
                                TRUE ~ lower_sens)) %>%
  mutate(fpr = 1-specificity)

# plot all levels together
avg_sens %>%
  ggplot(aes(x=fpr,y=mean_sensitivity,
             ymin=lower_sens,ymax=upper_sens)) +
  geom_line(aes(color=level),alpha=0.7) +
  geom_ribbon(aes(fill=level),alpha=0.2) +
  coord_equal() +
  geom_abline(intercept = 0,lty="dashed",color="grey50") +
  scale_x_continuous(expand = c(0,0)) +
  scale_y_continuous(expand = c(0,0)) +
  xlab("False Positive Rate") +
  ylab("Average True Positive Rate") +
  #facet_wrap(~level,ncol=3) +
  #scale_x_reverse(expand = c(0,0),labels = scales::percent_format(accuracy = 1)) +
  theme_classic() +
  theme(legend.position = "top",
        axis.text = element_text(size=11),
        axis.title = element_text(size=12),
        axis.text.x = element_text(vjust = -0.5),
        axis.title.x = element_text(vjust= -0.5)) +
  guides(color = guide_legend(nrow = 1,title=""),
         fill = guide_legend(nrow = 1,title="")) +
  scale_fill_manual(values=colors2) +
  scale_color_manual(values=colors2)
#ggsave("analysis/figures/average_roc_all.png",width=6)

#plot faceted
mean_auc <- read_csv("analysis/mean_AUC_by_model.csv")  %>% 
  select(level,rf) %>%
  rename(mean_AUC = rf) %>%
  mutate(level=factor(level,levels=levels,labels=levels_names))

avg_sens %>%
  inner_join(mean_auc,by="level") %>%
  ggplot(aes(x=fpr,y=mean_sensitivity,
             ymin=lower_sens,ymax=upper_sens)) +
    geom_line(aes(color=level),alpha=0.8,lwd=1) +
    geom_ribbon(aes(fill=level),alpha=0.2) +
    coord_equal() +
    geom_abline(slope=1,intercept = 0,lty="dashed",color="grey50") +
    scale_x_continuous(expand = c(0,0),breaks=seq(0,1,0.25),labels=c(0,seq(0.25,1,0.25))) +
    scale_y_continuous(expand = c(0,0),breaks=seq(0,1,0.25),labels=c(0,seq(0.25,1,0.25))) +
    xlab("False Positive Rate") +
    ylab("Average True Positive Rate") +
    facet_wrap(~level,nrow=2) +
    theme_classic() +
    theme(legend.position = "top",
          axis.text = element_text(size=9),
          axis.title = element_text(size=12),
          axis.title.x = element_text(vjust=0),
          panel.border = element_rect(colour = "black", fill=NA,size=0.75),
          panel.spacing.x = unit(4, "mm")) +
    guides(color = guide_legend(nrow = 1,title=""),
           fill = guide_legend(nrow = 1,title="")) +
    geom_text(aes(x = .7, y = .2,label = paste0("mean AUC\n",format(round(mean_AUC,digits=3),nsmall=3))),
              size=3.5) +
    scale_fill_manual(values=colors2) +
    scale_color_manual(values=colors2)
ggsave("analysis/figures/average_roc_by_level.png",width=7,height=5)
