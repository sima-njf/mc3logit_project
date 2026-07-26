
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mc3logit: Matched Case-Control Conditional Logit

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/sima-njf/mc3logit_project/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/sima-njf/mc3logit_project/actions/workflows/R-CMD-check.yaml)
[![test-coverage](https://github.com/sima-njf/mc3logit_project/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/sima-njf/mc3logit_project/actions/workflows/test-coverage.yaml)
[![pkgdown](https://github.com/sima-njf/mc3logit_project/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/sima-njf/mc3logit_project/actions/workflows/pkgdown.yaml)
[![codecov](https://codecov.io/gh/sima-njf/mc3logit_project/graph/badge.svg)](https://app.codecov.io/gh/sima-njf/mc3logit_project)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/sima-njf/mc3logit_project/blob/main/LICENSE.md)
<!-- badges: end -->

The `mc3logit` package implements permutation-based inference for
conditional logistic regression models fit to **matched case-control
data** – the kind of data you get when several individuals share the
same event and only some of them “act” (e.g. several police officers
responding to the same incident, only some of whom draw their firearm).
It builds on `survival::clogit()` and adds permutation-based p-values
and confidence intervals, following the approach used by Ridgeway (2016)
for exactly this kind of matched-officer data.

The package also ships:

- Two data simulators, `sim_events()` and `sim_events2()`, for
  generating synthetic matched case-control event data (useful for
  learning the package, and for power / type-I-error studies).
- `exposure_dyn()`, for computing running direct/indirect “exposure”
  covariates from a longitudinal event log without double-counting or
  looking into the future.
- `print()`/`plot()`/`confint()` methods for exploring and reporting a
  fitted `clogit_perm` model.

> This package originated in George G. Vega Yon’s
> [use_of_force](https://github.com/gvegayon/use_of_force) project (see
> `LICENSE`); this repository packages it standalone with expanded
> vignettes and documentation.

## Installation

<!-- You can install the released version of mc3logit from [CRAN](https://CRAN.R-project.org) with: -->

<!-- ``` r -->

<!-- install.packages("mc3logit") -->

<!-- ``` -->

You can install `mc3logit` from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("sima-njf/mc3logit_project", build_vignettes = TRUE)
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
#>  female       0.71    [ 0.41,  1.22]   0.22
#>   years       0.63*** [ 0.48,  0.83] < 0.01
#> exposed       3.50*** [ 1.66,  7.40] < 0.01
plot(ans)
```

<img src="man/figures/README-print-plot-1.png" width="100%" />

## Learning more

Full documentation, including all vignettes, is at
<https://sima-njf.github.io/mc3logit_project/>. The package ships five
vignettes:

- `vignette("getting-started")` – simulate data, fit `clogit_perm()`,
  and read off `print()`/`plot()`/`confint()` output.
- `vignette("permutation-inference")` – how within-stratum permutations
  are drawn, and how p-values and both flavors of confidence interval
  are computed.
- `vignette("validation")` – measured type-I error and power of the
  permutation test, plus a documented limitation (see below).
- `vignette("simulating-data")` – the `sim_events()`/`sim_events2()`
  data-generating process, tuning effect sizes, and using `nsims`.
- `vignette("dynamic-exposure")` – computing direct and indirect
  exposure covariates from an event log with `exposure_dyn()`.

Browse them locally with `browseVignettes("mc3logit")` once installed,
or read the source under [`vignettes/`](vignettes/).

## A note on validity

Permuting the raw outcome builds a reference distribution under the
*complete* null – “no covariate matters” – rather than the *partial*
null usually of interest, “this covariate doesn’t matter, the others
may.” When another covariate in the model carries substantial signal,
the reference distribution is too narrow and the resulting p-values are
**anti-conservative**.

`vignette("validation")` measures this directly. Treat `clogit_perm()`
p-values as reliable when the remaining covariates are weak, and
cross-check against the Wald p-values in `$fit` otherwise.
Residual-permutation schemes (Freedman & Lane, 1983) would address it
and are not yet implemented.

## References

Ridgeway, G. (2016). Officer risk factors associated with police
shootings: a matched case-control study. *Statistics and Public Policy*,
3(1), 1-6.

Knijnenburg, T. A., Wessels, L. F. A., Reinders, M. J. T., & Shmulevich,
I. (2009). Fewer permutations, more accurate P-values. *Bioinformatics*,
25(12), 161-168.
