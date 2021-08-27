library(png)
library(grid)
library(gridExtra)
library(tidyverse)

img1 <-  rasterGrob(as.raster(readPNG("analysis/figures/rf_AUC_all_level.png")), interpolate = FALSE)
img2 <-  rasterGrob(as.raster(readPNG("analysis/figures/sensitivity_at_90_specificity.png")), interpolate = FALSE)
grid.arrange(arrangeGrob(img1, left = textGrob("A", x = unit(1, "npc"), y = unit(0.85, "npc"), gp = gpar(fontface="bold"))),
             arrangeGrob(img2, left = textGrob("B", x = unit(1, "npc"), y = unit(0.85, "npc"), gp = gpar(fontface="bold"))),
             ncol = 2)
g <- arrangeGrob(arrangeGrob(img1, left = textGrob("A", x = unit(1, "npc"), y = unit(0.95, "npc"), gp = gpar(fontface="bold"))),
            arrangeGrob(img2, left = textGrob("B", x = unit(1, "npc"), y = unit(0.95, "npc"), gp = gpar(fontface="bold"))),
            ncol = 2)
ggsave("paper/figure_1.png",g,height=5,width=10)
