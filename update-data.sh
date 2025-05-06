#!/bin/bash

echo "Updating test data"
go run . ./executive_orders.csv

echo "Knitting rmarkdown"
R --vanilla --quiet -e "rmarkdown::render('executive-orders.Rmd')" < /dev/null
