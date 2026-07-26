# Shared fixtures. testthat sources helper-*.R before running any tests.

# A small but fittable matched case-control dataset plus its permutation fit.
#
# The refits inside clogit_perm() routinely hit "Loglik converged before
# variable ...; beta may be infinite" -- with small strata and a sparse
# covariate, some permuted datasets are separable. That is expected behaviour
# for permutation inference, not a defect, so it is suppressed here to keep
# test output readable.
fit_small <- function(seed = 22, nperm = 20, nevents = 80, nofficers = 100) {
  x <- sim_events(nevents, nofficers, seed = seed)
  suppressWarnings(clogit_perm(
    nperm = nperm,
    pointed000001 ~ female + years + exposed + strata(incidentid),
    data  = x,
    ncpus = 1
  ))
}
