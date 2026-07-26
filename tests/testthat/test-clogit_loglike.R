test_that("clogit_loglike returns 0 for uninformative strata", {
  x <- cbind(rnorm(4))
  expect_equal(clogit_loglike(c(1, 1, 1, 1), x, beta = 0.5), 0)
  expect_equal(clogit_loglike(c(0, 0, 0, 0), x, beta = 0.5), 0)
})

test_that("clogit_loglike matches a brute-force calculation for n=2, n1=1", {
  x <- cbind(c(0, 1))
  y <- c(1, 0)
  beta <- 0.7

  ans <- clogit_loglike(y, x, beta = beta)

  expected <- sum(x[1, ] * beta) - log(exp(x[1, ] * beta) + exp(x[2, ] * beta))

  expect_equal(ans, expected)
})

test_that("clogit_loglike defaults n1 to sum(y)", {
  set.seed(1)
  x <- cbind(rnorm(4))
  y <- c(1, 0, 0, 0)

  expect_equal(
    clogit_loglike(y, x, beta = 0.5),
    clogit_loglike(y, x, beta = 0.5, n1 = sum(y))
  )
})

test_that("clogit_loglike handles multi-column x without dropping dimensions", {
  # Regression test: x[y == 1, ] used to drop to a vector, which silently
  # changed the meaning of the %*% for k > 1.
  x <- cbind(c(0, 1, 2, 0), c(1, 0, 1, 1))
  y <- c(1, 1, 0, 0)
  beta <- c(0.3, -0.4)

  ans <- clogit_loglike(y, x, beta = beta)

  # Brute force over all choose(4, 2) assignments of two positives
  sets <- utils::combn(4L, 2L, simplify = FALSE)
  num  <- sum(x[c(1, 2), , drop = FALSE] %*% beta)
  den  <- log(sum(vapply(
    sets,
    function(s) exp(sum(x[s, , drop = FALSE] %*% beta)),
    numeric(1L)
  )))

  expect_equal(ans, num - den)
})

test_that("clogit_loglike agrees with survival::clogit on a small dataset", {
  # Two strata of size 2, one positive each -> exact conditional likelihood
  dat <- data.frame(
    id = c(1, 1, 2, 2),
    y  = c(1, 0, 0, 1),
    z  = c(0.5, -0.2, 1.1, 0.3)
  )

  beta <- 0.8

  ours <- sum(vapply(
    split(dat, dat$id),
    function(d) clogit_loglike(d$y, cbind(d$z), beta = beta),
    numeric(1L)
  ))

  fit <- survival::clogit(y ~ z + strata(id), data = dat)
  theirs <- as.numeric(stats::logLik(fit))

  # Our likelihood evaluated at the MLE must match clogit()'s logLik
  ours_at_mle <- sum(vapply(
    split(dat, dat$id),
    function(d) clogit_loglike(d$y, cbind(d$z), beta = stats::coef(fit)[["z"]]),
    numeric(1L)
  ))

  expect_equal(ours_at_mle, theirs, tolerance = 1e-6)
  expect_true(is.finite(ours))
})
