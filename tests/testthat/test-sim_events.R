sim_cols <- c(
  "officerid", "female", "years", "fixed_effect", "incidentid",
  "violence_level", "response_time", "first", "exposed", "pointed000001"
)

test_that("sim_events returns the documented columns", {
  x <- sim_events(50, 40, seed = 1)

  expect_s3_class(x, "data.frame")
  expect_true(all(sim_cols %in% colnames(x)))
  expect_true(nrow(x) > 0)
})

test_that("sim_events is reproducible given a fixed seed", {
  x1 <- sim_events(50, 40, seed = 123)
  x2 <- sim_events(50, 40, seed = 123)

  expect_equal(x1, x2)
})

test_that("sim_events nsims adds the requested number of outcome columns", {
  x <- sim_events(20, 20, seed = 5, nsims = 3)

  pointed_cols <- grep("^pointed", colnames(x), value = TRUE)
  expect_length(pointed_cols, 3)
})

test_that("sim_events produces a binary outcome and sane covariates", {
  x <- sim_events(200, 150, seed = 7)

  expect_true(all(x$pointed000001 %in% c(0, 1)))
  expect_true(all(x$female %in% c(0, 1)))
  expect_true(all(x$years >= 0))
  expect_true(all(x$exposed %in% c(0, 1)))
})

test_that("sim_events respects min/max officers per event", {
  x <- sim_events(200, 150, seed = 11, min_per_event = 2, max_per_event = 4)

  per_event <- table(x$incidentid)
  expect_true(all(per_event >= 2))
  expect_true(all(per_event <= 4))
})

test_that("different seeds give different draws", {
  x1 <- sim_events(50, 40, seed = 1)
  x2 <- sim_events(50, 40, seed = 2)

  expect_false(isTRUE(all.equal(x1$pointed000001, x2$pointed000001)))
})

test_that("sim_events2 accepts a predefined event/officer structure", {
  event_id   <- c(1, 1, 1, 2, 2, 3, 3, 3)
  officer_id <- c(1, 2, 3, 1, 4, 2, 3, 5)

  x <- sim_events2(
    event_id       = event_id,
    officer_id     = officer_id,
    officer_female = rep(c(0, 1), length.out = length(event_id)),
    officer_years  = rep(c(1, 5), length.out = length(event_id)),
    seed           = 99
  )

  expect_s3_class(x, "data.frame")
  expect_equal(nrow(x), length(event_id))
  expect_true(all(sim_cols %in% colnames(x)))
})

test_that("sim_events2 is reproducible given a fixed seed", {
  args <- list(
    event_id       = c(1, 1, 2, 2, 3, 3),
    officer_id     = c(1, 2, 1, 3, 2, 3),
    officer_female = c(0, 1, 0, 1, 1, 1),
    officer_years  = c(1, 2, 1, 3, 2, 3),
    seed           = 4242
  )

  expect_equal(do.call(sim_events2, args), do.call(sim_events2, args))
})

test_that("simulated data is fittable by clogit_perm", {
  x <- sim_events(120, 100, seed = 3)

  ans <- clogit_perm(
    nperm = 10,
    pointed000001 ~ female + years + strata(incidentid),
    data  = x,
    ncpus = 1
  )

  expect_s3_class(ans, "clogit_perm")
})
