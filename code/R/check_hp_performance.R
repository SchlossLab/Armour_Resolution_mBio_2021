library(tidyverse)
library(docopt)
library(mikropml)
library(cowplot)

'check hp performance

Usage:
  check_hp_performance.R --input=<csv>

Options
  --input=<csv>  HP performance file

' -> doc

args <- docopt(doc)

hp_in <- read_csv(args$input)

method <- args$input %>%
  basename() %>% 
  str_replace("hp_","") %>% 
  str_replace(".[0-9]+.csv","")


if(method == "glmnet"){
    min_lambda <- min(hp_in$lambda)

    if(min_lambda < 0.0001) {
	plot_hp_performance(hp_in,lambda,AUC) +
	   scale_x_continuous(trans='log10')
    }else{
	plot_hp_performance(hp_in,lambda,AUC)
    }
    ggsave("hp_plot.png")
}

if(method == "rpart2"){
    plot_hp_performance(hp_in,maxdepth,AUC) 
    ggsave("hp_plot.png")
}

if(method == "rf"){
    plot_hp_performance(hp_in,mtry,AUC)
    ggsave("hp_plot.png")
}

if(method == "svmRadial"){
    mod_hp <- hp_in    
    mod_hp$sigma <- as.factor(mod_hp$sigma)
    p1 <- ggplot(mod_hp, aes(x=C,y=AUC,color=sigma)) +
	geom_line() + geom_point() +
	scale_x_continuous(trans='log10')

    mod_hp <- hp_in
    mod_hp$C <- as.factor(mod_hp$C)
    p2 <- ggplot(mod_hp, aes(x=sigma,y=AUC,color=C)) +
	geom_line() + geom_point() +
	scale_x_continuous(trans='log10')
    plot_grid(p1,p2)
    ggsave("hp_plot.png",width=10,height=5)
}
