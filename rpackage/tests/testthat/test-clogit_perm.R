test_that("clogit_perm returns a well-formed clogit_perm object", {
  x <- sim_events(80, 100, seed = 22)

  ans <- clogit_perm(
    nperm = 20,
    pointed000001 ~ female + years + exposed + strata(incidentid),
    data  = x,
    ncpus = 1
  )

  expect_s3_class(ans, "clogit_perm")
  expect_true(all(c("pvals", "fit", "coefs", "candidates", "formula", "errors") %in% names(ans)))
  expect_equal(nrow(ans$coefs), 20 - nrow(ans$errors))
  expect_equal(ncol(ans$coefs), length(stats::coef(ans$fit)))
})

test_that("clogit_perm methods run without error", {
  x <- sim_events(80, 100, seed = 22)

  ans <- clogit_perm(
    nperm = 20,
    pointed000001 ~ female + years + exposed + strata(incidentid),
    data  = x,
    ncpus = 1
  )

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
