test_that("clogit_perm returns a well-formed clogit_perm object", {
  ans <- fit_small()

  expect_s3_class(ans, "clogit_perm")
  expect_true(all(c("pvals", "fit", "coefs", "candidates", "formula", "errors") %in% names(ans)))
  expect_equal(nrow(ans$coefs), 20 - nrow(ans$errors))
  expect_equal(ncol(ans$coefs), length(stats::coef(ans$fit)))
})

test_that("clogit_perm methods run without error", {
  ans <- fit_small()

  expect_type(stats::coef(ans), "double")
  expect_true(is.matrix(stats::vcov(ans)))
  expect_type(stats::nobs(ans), "double")
  expect_s3_class(stats::formula(ans), "formula")
  expect_true(is.matrix(stats::confint(ans)))
  expect_true(is.matrix(stats::confint(ans, which. = "perm")))
  expect_output(print(ans), "CONDITIONAL LOGIT")
})

test_that("clogit_perm errors without a strata() term", {
  x <- sim_events(20, 20, seed = 1)

  expect_error(
    clogit_perm(nperm = 5, pointed000001 ~ female + years, data = x, ncpus = 1),
    "strata"
  )
})

test_that("clogit_perm errors when the strata term is not a column", {
  x <- sim_events(20, 20, seed = 1)

  expect_error(
    clogit_perm(
      nperm = 5,
      pointed000001 ~ female + strata(not_a_column),
      data  = x,
      ncpus = 1
    ),
    "not present"
  )
})

test_that("clogit_perm errors when the formula has no response", {
  x <- sim_events(20, 20, seed = 1)

  expect_error(
    clogit_perm(nperm = 5, ~ female + strata(incidentid), data = x, ncpus = 1),
    "dependent variable"
  )
})

test_that("clogit_perm$errors reports the failed permutations faithfully", {
  # Regression test: the error messages used to be pulled out of -coefs- *after*
  # it had been collapsed into a matrix, so they were silently wrong.
  ans <- fit_small()

  expect_s3_class(ans$errors, "data.frame")
  expect_named(ans$errors, c("id", "msg"))
  expect_type(ans$errors$msg, "character")
  expect_true(all(ans$errors$id >= 1L & ans$errors$id <= 20L))
  expect_equal(nrow(ans$coefs) + nrow(ans$errors), 20L)
})

test_that("p-values are in [0, 1] and never exactly zero", {
  ans <- fit_small()

  expect_true(all(ans$pvals >= 0))
  expect_true(all(ans$pvals <= 1))
  # Knijnenburg et al. (2009) pseudo-count: p is floored at 1/nperm
  expect_true(all(ans$pvals >= 1 / 20))
})

test_that("permutation draws are not degenerate for two-row strata", {
  # Regression test. clogit_perm() used to permute via permute(), which builds
  # a pairwise matching and so can never leave a row in place. For a stratum of
  # exactly two rows that made the draw deterministic -- the pair always traded
  # places -- so every permutation produced the *same* dataset and the
  # reference distribution collapsed to a single point.
  set.seed(11)

  n_strata <- 120
  dat <- data.frame(
    incidentid = rep(seq_len(n_strata), each = 2L),
    female     = rbinom(2L * n_strata, 1, 0.5),
    years      = round(runif(2L * n_strata, 0, 10))
  )
  # Exactly one positive per stratum -> a classic 1:1 matched design
  dat$y <- rep(c(1L, 0L), times = n_strata)

  ans <- suppressWarnings(clogit_perm(
    nperm = 50,
    y ~ female + years + strata(incidentid),
    data  = dat,
    ncpus = 1
  ))

  # The permuted coefficients must actually vary
  expect_gt(length(unique(ans$coefs[, "female"])), 1L)
  expect_gt(stats::sd(ans$coefs[, "female"]), 0)
})

test_that("within-stratum shuffling preserves each stratum's positive count", {
  set.seed(12)

  groups <- rep(1:40, each = 3)
  idx    <- split(seq_along(groups), groups)
  y      <- rep(c(1, 1, 0), times = 40)

  for (i in 1:50) {
    ord <- seq_along(groups)
    for (g in idx) ord[g] <- sample(g)

    expect_true(all(groups[ord] == groups))
    expect_equal(
      as.numeric(tapply(y[ord], groups, sum)),
      as.numeric(tapply(y,      groups, sum))
    )
  }
})

test_that("confint returns both interval flavors with the right shape", {
  ans <- fit_small()

  k <- length(stats::coef(ans))

  ci_coef <- stats::confint(ans, which. = "coef")
  ci_sd   <- stats::confint(ans, which. = "coef", sigma_perm = TRUE)
  ci_dist <- stats::confint(ans, which. = "dist")

  for (ci in list(ci_coef, ci_sd, ci_dist)) {
    expect_equal(dim(ci), c(k, 2L))
    expect_true(all(ci[, 1] <= ci[, 2]))
  }

  # Wider levels give wider intervals
  narrow <- stats::confint(ans, level = 0.80)
  wide   <- stats::confint(ans, level = 0.99)
  expect_true(all(diff(t(wide)) >= diff(t(narrow))))
})
