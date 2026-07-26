# Agent Instructions for mc3logit

## Package Overview

`mc3logit` implements permutation-based inference for conditional logistic
regression on **matched case-control data**: several units share an event
(a matched set / stratum) and only some of them act. It builds on
`survival::clogit()` and follows Ridgeway (2016).

The heavy lifting is in C++ (`src/`): event simulation (`simforce.cpp`),
dynamic exposure (`exposure.cpp`) and permutation candidates
(`premute.cpp`).

## Development Principles

- **Minimal dependencies.** Runtime imports are `Rcpp`, `stats`, `graphics`,
  `parallel` and `utils`, plus `survival` in Depends. Do not add tidyverse
  packages as Imports or Suggests.
- **Base R graphics only** in vignettes, examples and methods -- `plot()`,
  `hist()`, `boxplot()`, `barplot()`. No ggplot2.
- **Vignettes are Quarto** (`.qmd`, `%\VignetteEngine{quarto::html}`).
  Building them requires the Quarto CLI, not just the `quarto` R package.
- **Avoid multi-line `cat()`** for output in vignettes and examples. Print a
  `data.frame` or use `knitr::kable()` instead; a single-line `cat()` is fine.

## Statistical Invariants

These are the properties the package's correctness rests on. Do not change
them without a simulation study demonstrating calibration.

- **Permutations must be uniform within strata.** `clogit_perm()` shuffles
  row positions uniformly inside each stratum. A draw that always moves every
  row is not a permutation -- it is a fixed relabelling. For a stratum of
  size `m`, a row must stay in place with probability `1/m`.
- **`permute()` is not uniform** and must not be used to build a reference
  distribution. It builds a pairwise matching and cannot leave a row in
  place; for two-row strata it is deterministic. It is exported only for
  backwards compatibility and candidate inspection.
- **Every permutation must preserve each stratum's positive count.** That is
  what conditional logit conditions on.
- Permuting the raw outcome tests the *complete* null. With a nuisance
  covariate carrying real signal the test is anti-conservative; see
  `vignettes/validation.qmd`.

## Validation

Before submitting changes, run:

```r
devtools::document()   # after touching roxygen or Rcpp exports
devtools::test()
devtools::check()
```

`devtools::check()` requires the Quarto CLI for the vignettes. If it is
unavailable locally, `R CMD build --no-build-vignettes .` plus
`devtools::test()` is a reasonable substitute -- CI builds the vignettes.

If you touch anything in `R/clogit_perm.R` or `src/premute.cpp`, also re-run
the calibration check in `vignettes/validation.qmd` and confirm the
complete-null rejection rate is near the nominal level.

## Common Pitfalls

- **`sample(x)` when `length(x) == 1` means `sample(1:x)`.** The
  within-stratum shuffle in `clogit_perm()` drops singleton strata up front
  precisely to avoid this; keep that filter.
- **Do not add `PKG_CXXFLAGS` with `-O3`** or reinstate `CXX_STD = CXX11`.
  CRAN forbids overriding optimization flags, and C++11 has been the wrong
  thing to specify since R 4.3.
- **Helper classes in `src/` must live in an anonymous namespace.**
  `exposure.cpp` and `simforce.cpp` both define a class called `Event`; at
  global scope the linker conflates their destructors and heap-corrupts R.
- `Rcpp::compileAttributes()` must be re-run before `roxygen2::roxygenize()`
  whenever an `// [[Rcpp::export]]` signature changes.
- Roxygen comments for C++ exports live in `src/*.cpp` (as `//'`), not in
  `R/RcppExports.R`, which is generated.
