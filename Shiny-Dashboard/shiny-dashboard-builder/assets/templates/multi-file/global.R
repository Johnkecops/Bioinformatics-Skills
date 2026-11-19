# global.R runs once, before ui.R and server.R; objects here are visible to both.
# Files in R/ are sourced automatically right after this (shiny >= 1.5), so they
# can use packages loaded here.
library(shiny)
library(bslib)
library(ggplot2)

dat <- ToothGrowth
dat$dose <- factor(dat$dose)
