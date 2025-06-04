#!/bin/bash

EXECUTIVE_ORDER_FILE="executive_orders.csv"

echo "Updating test data"
Rscript ./update-data.R "$EXECUTIVE_ORDER_FILE"
date --iso-8601 > last_update

echo "Knitting rmarkdown"
Rscript --vanilla -e "rmarkdown::render('executive-orders.Rmd')"
