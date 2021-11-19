library(tidyverse)

### VARIABLES ########
levels <- c("phylum","class","order","family","genus","otu","asv")
levels_names <- c("Phylum","Class","Order","Family","Genus","OTU","ASV")

colors <- c("#D04C44","#E7834E","#E6A444","#829E88","#83BCC3","#7989A4","#B29ABA")
names(colors) <- levels

colors2 <- colors
names(colors2) <- levels_names

### MAIN ########

#read in prevalence table
prevalence <- read_csv("analysis/prevalence_by_level.csv") %>%
  mutate(level = factor(level,levels=levels))

tax_count <- prevalence %>%
  filter(kept==1) %>%
  group_by(level) %>%
  mutate(numOTU = n_distinct(name)) %>%
  select(level,numOTU) %>%
  distinct()

pct_bins <- NULL
level_nOTU <- NULL
for(l in levels){
  sub_data <- prevalence %>%
    filter(level==l,kept==1)
  hist <- hist(sub_data$total_prevalence,breaks = seq(0,1,0.1),plot=FALSE)

  nOTU <- sub_data %>%
    select(name) %>%
    n_distinct()

  level_nOTU <- bind_rows(level_nOTU,
                          data.frame(l,nOTU))

  pct_bins <- pct_bins %>%
    bind_rows(data.frame(level=l,
                         prev=hist$breaks[-1],
                         count=hist$counts,
                         pct=hist$counts/nOTU))
}

level_nOTU <- level_nOTU %>%
  mutate(level_name = levels_names)
labs <- paste0(level_nOTU$level_name," (",level_nOTU$nOTU,")")
pal <- colors2
names(pal) <- labs

pct_bins %>%
  mutate(level=factor(level,levels=levels,labels=labs)) %>%
  ggplot(aes(x=prev*100,y=pct,fill=level)) +
  geom_bar(stat = "identity") +
  facet_wrap(~level,ncol=2) +
  scale_y_continuous(expand=c(0,0),limits=c(0,0.85),labels = scales::percent_format()) +
  scale_x_continuous(expand=c(0,0),breaks = seq(0,100,10)) +
  xlab("Percent of Samples") +
  ylab("Percent of Taxa") +
  theme_classic() +
  theme(legend.position = "none",
        axis.text = element_text(size=11),
        axis.title = element_text(size=14),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.border = element_rect(colour = "black", fill=NA,size=0.75),
        panel.spacing.x = unit(4, "mm"),
        strip.text = element_text(size=12)) +
  geom_text(aes(label = paste0((round(pct,digits=2)*100),"%")),nudge_y=0.08) +
  scale_fill_manual(values=pal)
ggsave("analysis/figures/prevalence.tiff",
       width=6.87,height=6,units="in",
       compression = "lzw")
