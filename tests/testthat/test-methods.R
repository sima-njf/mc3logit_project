test_that("print reports odds ratios by default and betas on request", {
  ans <- fit_small()

  odds  <- capture.output(print(ans, odds = TRUE))
  betas <- capture.output(print(ans, odds = FALSE))

  expect_match(paste(odds, collapse = "\n"), "odds")
  expect_match(paste(betas, collapse = "\n"), "betas")
  expect_false(identical(odds, betas))
})

test_that("print honors the LaTeX output mode", {
  ans <- fit_small()

  out <- paste(capture.output(print(ans, out = "latex")), collapse = "\n")
  expect_match(out, "hphantom", fixed = TRUE)
})

test_that("print applies custom labels", {
  ans <- fit_small()

  labs <- c(female = "Female officer", years = "Years of service",
            exposed = "Previously exposed")

  out <- paste(capture.output(print(ans, labels = labs)), collapse = "\n")
  expect_match(out, "Female officer", fixed = TRUE)
})

test_that("print returns its argument invisibly", {
  ans <- fit_small()

  tmp <- tempfile()
  on.exit(unlink(tmp), add = TRUE)

  sink(tmp)
  res <- expect_invisible(print(ans))
  sink()

  expect_s3_class(res, "clogit_perm")
})

test_that("plot draws without error for both scales", {
  ans <- fit_small()

  tmp <- tempfile(fileext = ".png")
  on.exit(unlink(tmp), add = TRUE)

  png(tmp)
  expect_silent(plot(ans))
  expect_silent(plot(ans, odds = TRUE))
  expect_silent(plot(ans, which. = "dist"))
  dev.off()

  expect_true(file.exists(tmp))
})

test_that("vcov is a symmetric matrix over the permutation draws", {
  ans <- fit_small()

  v <- stats::vcov(ans)
  k <- length(stats::coef(ans))

  expect_equal(dim(v), c(k, k))
  expect_equal(v, t(v))
  expect_true(all(diag(v) >= 0))
})

test_that("coef and formula round-trip the underlying fit", {
  ans <- fit_small()

  expect_equal(stats::coef(ans), stats::coef(ans$fit))
  expect_equal(stats::nobs(ans), stats::nobs(ans$fit))
  expect_equal(
    deparse(stats::formula(ans)),
    deparse(ans$formula)
  )
})

test_that("the package namespace carries no stray top-level objects", {
  # Regression test: R/exposure.R used to run `set.seed(123)` plus a handful of
  # scratch assignments at build time, which reseeded the user's RNG on load.
  ns <- asNamespace("mc3logit")
  expect_false(any(c("x", "y", "ord") %in% ls(ns)))
})

test_that("loading the package leaves the RNG stream untouched", {
  set.seed(999)
  before <- .Random.seed

  # A no-op reference to the namespace
  invisible(asNamespace("mc3logit"))

  expect_equal(.Random.seed, before)
})
