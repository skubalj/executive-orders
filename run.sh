#!/bin/bash

echo "Updating test data"

EXECUTIVE_ORDER_FILE="executive_orders.csv"

# Rscript ./update-data.R "$EXECUTIVE_ORDER_FILE"
go run ./update-data.go $EXECUTIVE_ORDER_FILE
date --iso-8601 > last_update

echo "Knitting rmarkdown"
Rscript --vanilla -e "rmarkdown::render('executive-orders.Rmd')"
