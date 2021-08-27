library(tidyverse)
library(mosaic)

### FUNCTIONS ##################
perm_p_value_senspec <- function(data, level1, level2){
  # subset results to select AUC and condition columns and
  # filter to only the two conditions of interest
  test_subsample <- data %>%
    mutate(level = as.character(level)) %>%
    select(level,sensitivity) %>%
    filter((level == level1 | level == level2))
  # quantify the absolute value of the difference in mean AUC between the two conditions (observed difference)
  obs <- abs(diff(mosaic::mean(sensitivity ~ level, data = test_subsample)))
  # use mosaic to shuffle condition labels and calculate difference in mean AUC - repeat 10,000 times
  null <- do(10000) * diff(mosaic::mean(sensitivity ~ shuffle(level), data = test_subsample))
  n <- length(null[,1]) #number of shuffled calculations
  # r = #replications at least as extreme as observed effect
  r <- sum(abs(null[,1]) >= obs) #count number of shuffled differences as big or bigger than observed difference
  # compute Monte Carlo p-value with correction (Davison & Hinkley, 1997)
  p.value=(r+1)/(n+1)
  return(p.value)
}

### MAIN #########################
levels <- c("phylum","class","order","family","genus","otu","asv")
levels_names <- c("Phylum","Class","Order","Family","Genus","OTU","ASV")

sens_spec90 <- read_csv("analysis/sens_spec_by_level.csv") %>%
  filter(specificity == 0.9) %>%
  mutate(level = factor(level,levels=rev(levels),labels=rev(levels_names)))


senspec_pvals <- expand_grid(x=1:length(levels_names),
                             y=1:length(levels_names)) %>%
  filter(x < y) %>%
  mutate(level1 = levels_names[x],
         level2 = levels_names[y]) %>%
  select(-x, -y) %>%
  group_by(level1, level2) %>%
  summarize(p_value = perm_p_value_senspec(sens_spec90,level1,level2),
            .groups="drop") %>%
  write_csv("analysis/sens_spec90_pvals.csv")
