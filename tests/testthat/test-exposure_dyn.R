make_event_log <- function() {
  data.frame(
    event = c(1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4),
    id    = c(1, 2, 3, 1, 2, 4, 2, 3, 4, 5, 5, 1, 6, 2),
    fired = c(1, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1)
  )
}

test_that("exposure_dyn matches the documented example", {
  dat <- make_event_log()

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
  dat <- make_event_log()

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

test_that("exposure_dyn never looks into the future", {
  dat <- make_event_log()

  counts <- with(dat, exposure_dyn(
    id_indiv = id, id_events = event, actions = fired, offset = 0
  ))

  # Cumulative counts are non-decreasing in event order for every individual
  ord <- order(dat$id, dat$event)
  by_id <- split(as.data.frame(counts)[ord, ], dat$id[ord])

  for (d in by_id) {
    for (nm in c("exposure_i_cum", "exposure_d_cum")) {
      if (nm %in% colnames(d))
        expect_true(all(diff(d[[nm]]) >= 0))
    }
  }
})

test_that("exposure_dyn returns all documented columns", {
  dat <- make_event_log()

  counts <- with(dat, exposure_dyn(
    id_indiv = id, id_events = event, actions = fired, offset = 0
  ))

  expect_true(all(c(
    "cumsum", "exposure_i", "exposure_d", "exposure_i_cum", "exposure_d_cum"
  ) %in% colnames(counts)))
  expect_true(is.numeric(counts))
})

test_that("an all-zero action vector produces no exposure", {
  dat <- make_event_log()
  dat$fired <- 0

  counts <- with(dat, exposure_dyn(
    id_indiv = id, id_events = event, actions = fired, offset = 0
  ))

  expect_true(all(counts[, "cumsum"] == 0))
  expect_true(all(counts[, "exposure_i"] == 0))
  expect_true(all(counts[, "exposure_d"] == 0))
})
