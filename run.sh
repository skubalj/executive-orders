#!/bin/bash

echo "Updating test data"
Rscript ./update-data.R ./executive_orders.csv

echo "Knitting rmarkdown"
Rscript --vanilla -e "rmarkdown::render('executive-orders.Rmd')"
