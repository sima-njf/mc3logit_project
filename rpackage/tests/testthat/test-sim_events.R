test_that("sim_events returns the documented columns", {
  x <- sim_events(50, 40, seed = 1)

  expect_s3_class(x, "data.frame")
  expect_true(all(c(
    "officerid", "female", "years", "fixed_effect", "incidentid",
    "violence_level", "response_time", "first", "exposed", "pointed000001"
  ) %in% colnames(x)))
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
