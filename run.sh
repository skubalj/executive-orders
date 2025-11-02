#!/bin/bash

EXECUTIVE_ORDER_FILE="executive_orders.csv"

echo "Updating executive order data"
Rscript ./update-data.R "$EXECUTIVE_ORDER_FILE"
date -Idate > last_update

echo "Knitting rmarkdown"
Rscript --vanilla -e "rmarkdown::render('executive-orders.Rmd')"
