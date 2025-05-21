#!/bin/bash

EXECUTIVE_ORDER_FILE="executive_orders.csv"

echo "Updating test data"

deno run \
    --allow-read="$EXECUTIVE_ORDER_FILE" \
    --allow-write="$EXECUTIVE_ORDER_FILE" \
    --allow-net="www.federalregister.gov:443" \
    ./update-data.ts \
    "$EXECUTIVE_ORDER_FILE"

# Rscript ./update-data.R "$EXECUTIVE_ORDER_FILE"
date --iso-8601 > last_update

echo "Knitting rmarkdown"
Rscript --vanilla -e "rmarkdown::render('executive-orders.Rmd')"
