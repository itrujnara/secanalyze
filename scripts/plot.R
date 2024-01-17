library(secplot)
library(dplyr)
library(ggplot2)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Insufficient arguments. Usage: Rscript plot.R [infile] [outfile]")
}

structures <- readLines(args[1]) %>% lapply(read.ss)

p <- ss_plot_many(structures)

ggsave(args[2], plot = p, bg = "white")
