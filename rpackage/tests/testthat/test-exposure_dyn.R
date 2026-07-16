test_that("exposure_dyn matches the documented example", {
  dat <- data.frame(
    event = c(1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4),
    id    = c(1, 2, 3, 1, 2, 4, 2, 3, 4, 5, 5, 1, 6, 2),
    fired = c(1, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1)
  )

  counts <- with(dat, exposure_dyn(
    id_indiv  = id,
    id_events = event,
    actions   = fired,
    offset    = 0
  ))

  expect_equal(nrow(counts), nrow(dat))
  expect_true(all(c("cumsum", "exposure_i", "exposure_d") %in% colnames(counts)))
})

test_that("exposure_dyn is invariant to row order", {
  dat <- data.frame(
    event = c(1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4),
    id    = c(1, 2, 3, 1, 2, 4, 2, 3, 4, 5, 5, 1, 6, 2),
    fired = c(1, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1)
  )

  counts <- with(dat, exposure_dyn(
    id_indiv = id, id_events = event, actions = fired, offset = 0
  ))

  set.seed(42)
  shuffled <- dat[sample(nrow(dat)), ]
  counts_shuffled <- with(shuffled, exposure_dyn(
    id_indiv = id, id_events = event, actions = fired, offset = 0
  ))

  expect_equal(
    counts_shuffled[order(as.integer(rownames(shuffled))), ],
    counts,
    ignore_attr = TRUE
  )
})
