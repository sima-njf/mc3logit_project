# mc3logit 0.1.0

First packaged release. `mc3logit` was extracted from George G. Vega Yon's
[use_of_force](https://github.com/gvegayon/use_of_force) project and is
packaged here standalone with expanded documentation and tests.

## Breaking change: how permutations are drawn

`clogit_perm()` previously built each permutation with `permute()`, which
constructs a random *pairwise matching* among candidate rows. Because
`find_candidates()` never lists a row as its own candidate, that draw can
never leave a row in place -- and for a stratum of exactly two rows it is
therefore **deterministic**: the pair always trades places, where a uniform
draw would leave it untouched half the time.

Small strata dominate matched case-control data, so a large share of every
permuted dataset was identical from draw to draw. That collapsed the spread
of the reference distribution and made the test badly anti-conservative: in
simulation, the complete-null rejection rate was about **0.20 against a
nominal 0.05**.

`clogit_perm()` now draws a **uniform shuffle of the rows within each
stratum**, which is the correct draw given that it always matches on the
stratum id exactly. Measured complete-null rejection rate is now near
nominal. **P-values and confidence intervals from earlier versions should be
recomputed.**

`permute()` and `find_candidates()` remain exported and unchanged for
backwards compatibility; `permute()` now documents the non-uniformity in a
`Warning` section.

## Known limitation

Permuting the raw outcome tests the *complete* null ("no covariate
matters"), not the *partial* null actually of interest ("this covariate
doesn't matter, others may"). When a nuisance covariate carries real signal
the reference distribution is too narrow and the test remains
anti-conservative. See `vignette("validation")` for measurements and
guidance. Residual-permutation schemes (Freedman & Lane, 1983; ter Braak,
1992) would address this and are not currently implemented.

## Bug fixes

* Fixed a crash that made `sim_events()` and `sim_events2()` segfault R on
  every call. `exposure.cpp` and `simforce.cpp` each declared an unrelated
  class named `Event` at global scope; because both are non-virtual classes
  with implicitly-inline special members, the linker conflated their
  identically-mangled destructors, corrupting the heap. Both files now wrap
  their internal helper types in an anonymous namespace.

* Fixed the duplicate-officer check in the incident sampler, which used
  `continue` in the wrong loop and so never actually prevented the same
  officer from being added to one incident twice.

* Removed stray top-level code in `R/exposure.R` that ran `set.seed(123)` at
  build time, silently resetting the user's RNG stream on package load and
  leaving `x`, `y` and `ord` in the package namespace.

* `clogit_perm()$errors` reported meaningless messages: the error text was
  read out of `coefs` *after* that object had been overwritten with the
  matrix of successful fits. Messages are now captured beforehand, and `msg`
  is a character column rather than a factor.

* `clogit_loglike()` no longer drops matrix dimensions when subsetting `x`,
  which silently changed the meaning of the linear predictor for models with
  more than one covariate.

* Qualified `stats::pnorm()`, `stats::qnorm()`, `stats::cov()` and
  `utils::combn()`, which were previously called without being imported.

## Documentation

* `clogit_loglike()` is now exported and documented. It was previously
  excluded from the build via `.Rbuildignore`, so it did not exist in the
  installed package despite carrying an `@export` tag.

* Vignettes are now Quarto (`.qmd`) documents:
  `getting-started`, `permutation-inference`, `simulating-data`,
  `dynamic-exposure`, and a new `validation` vignette that measures the
  test's type-I error and power.

* Added a pkgdown site, organized reference index, and this changelog.

## Infrastructure

* Added a test suite (`testthat`, 3rd edition) covering the model fitting,
  simulators, exposure helper, S3 methods and permutation internals,
  including regression tests for each bug above.

* R-CMD-check now runs on six OS/R-version configurations, uses `--as-cran`
  on Linux release, and fails on warnings. Added coverage and pkgdown
  workflows.

* Removed `src/Makevars` and `src/Makevars.win`. They forced `-O3`, which
  CRAN policy forbids, and set `CXX_STD = CXX11`, which has been a check NOTE
  since R 4.3. The sources only use C++11 features, which the current default
  standard subsumes.
