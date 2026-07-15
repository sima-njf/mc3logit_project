
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mc3logit: Matched Case-Control Conditional Logit

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/sima-njf/mc3logit_project/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/sima-njf/mc3logit_project/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/sima-njf/mc3logit_project/branch/master/graph/badge.svg)](https://app.codecov.io/gh/sima-njf/mc3logit_project)
<!-- badges: end -->

The `mc3logit` package implements permutation-based inference for
conditional logistic regression models. Permutation-based methods for
matched case-control logit were notably used by Ridgeway (2016).

## Installation

<!-- You can install the released version of mc3logit from [CRAN](https://CRAN.R-project.org) with: -->

<!-- ``` r -->

<!-- install.packages("mc3logit") -->

<!-- ``` -->

You can install `mc3logit` from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("sima-njf/mc3logit_project", subdir = "rpackage")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(mc3logit)
#> Loading required package: survival

# Simulating data
x <- sim_events(200, 300, seed = 122)

# Fitting
ans <- clogit_perm(
  nperm = 1000,
  pointed000001 ~ female + years + exposed + strata(incidentid),
  data = x
  )
```

``` r
print(ans)
#> 
#> CONDITIONAL LOGIT (WITH PERMUTATION)
#>   N events: 105
#>     N perm: 1000
#>          N: 625
#>        AIC: 133.32
#>        BIC: 141.28
#> MODEL PARAMETERS (odds):
#>  female       0.71*   [ 0.48,  1.06]   0.10
#>   years       0.63*** [ 0.48,  0.83] < 0.01
#> exposed       3.50*** [ 1.66,  7.40] < 0.01
plot(ans)
```

<img src="man/figures/README-print-plot-1.png" width="100%" />
