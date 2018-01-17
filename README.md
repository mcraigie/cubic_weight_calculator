# Average Cubic Weight Calculator

This tool finds the average cubic weight for a set of products

It was designed for and tested with ruby 2.4.1 and does require any non-standard libraries

All configuration is stored in ./config.json

##Configuration options:

* api_host: the host machine for the products API you wish to query
* starting_page: the API query for the first page of products
* categories: an array of category names to be included in the calculation
* include_sizeless: whether or not to filter out products with no dimensions, or treat their cubic weight as 0
* conversion_factor_kg_m3: the cubic weight conversion factor specified in kilograms per cubic meter
* result_unit: whether the result should be provided in kilograms or grams
* result_rounding: how many decimal places should be included in the result

##Usage:

```bash
# if the script has the executable permission:
$ ./calculate_acw.rb
> Average Cubic Weight for Air Conditioners (sizeless: excluded): 41.61kg
# otherwise
ruby calculate_acw.rb
> Average Cubic Weight for Air Conditioners (sizeless: excluded): 41.61kg
```
