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
