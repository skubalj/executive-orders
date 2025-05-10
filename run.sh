#!/bin/bash

echo "Updating test data"
go run . ./executive_orders.csv

echo "Knitting rmarkdown"
Rscript --vanilla -e "rmarkdown::render('executive-orders.Rmd')"
