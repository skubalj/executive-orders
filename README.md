# Executive Orders

In modern times, every administration is criticized for overusing executive
orders, yet rarely are citizens actually presented with statistics. How common
are executive orders? Which presidents actually issue the most? Are presidents
really issuing an unprecedented number of orders?

This repository analyzes publicly available data to make it easy to see which
presidents issue more executive orders than others. However, we must note this
repository _does not_ analyze the _content_ of those orders.

## Running

To generate the charts on a Unix system (including MacOS), simply run the
`run.sh` script in the root of the repository. This script does three things:

1. It downloads the latest executive order data from
   [federalregister.gov](https://www.federalregister.gov)
2. It creates a file called `last_update` which simply notes the date when the
   executive order data was last fetched. This is used to calculate accurate
   orders per day rates for the incumbent.
3. It knits the R markdown file containing the analyses.

The results will be written to `executive-orders.html`. Open this file with your
internet browser to view the charts.

## License

This is free and unencumbered software released into the public domain.

This project exists as a matter of public interest. In a functioning democracy,
citizens have a right to understand what is happening in their government and
how it compares to the past.
