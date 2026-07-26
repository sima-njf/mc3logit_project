strata_features <- function(grp) {
  cbind(as.integer(as.factor(grp)))
}

test_that("find_candidates only matches rows within the same stratum", {
  grp  <- c(1, 1, 1, 2, 2, 3, 3, 3, 3)
  cand <- find_candidates(strata_features(grp), upper = 0, lower = 0, as_abs = TRUE)

  expect_length(cand, length(grp))

  for (i in seq_along(cand)) {
    # find_candidates is zero-indexed
    partners <- cand[[i]] + 1L
    expect_true(all(grp[partners] == grp[i]))
  }
})

test_that("find_candidates is symmetric", {
  grp  <- c(1, 1, 2, 2, 2, 3)
  cand <- find_candidates(strata_features(grp), upper = 0, lower = 0, as_abs = TRUE)

  for (i in seq_along(cand)) {
    for (j in cand[[i]] + 1L) {
      expect_true(i %in% (cand[[j]] + 1L))
    }
  }
})

test_that("a wider band lets rows match across strata", {
  grp <- c(1, 1, 2, 2, 3, 3)

  tight <- find_candidates(strata_features(grp), upper = 0, lower = 0, as_abs = TRUE)
  loose <- find_candidates(strata_features(grp), upper = 1, lower = 0, as_abs = TRUE)

  expect_true(
    sum(lengths(loose)) > sum(lengths(tight))
  )
})

test_that("permute returns a valid permutation of the rows", {
  set.seed(1)
  grp  <- rep(1:5, each = 4)
  cand <- find_candidates(strata_features(grp), upper = 0, lower = 0, as_abs = TRUE)

  p <- permute(cand) + 1L

  expect_length(p, length(grp))
  expect_setequal(p, seq_along(grp))
})

test_that("permute never moves a row outside its own stratum", {
  set.seed(2)
  grp  <- rep(1:6, each = 3)
  cand <- find_candidates(strata_features(grp), upper = 0, lower = 0, as_abs = TRUE)

  for (i in 1:50) {
    p <- permute(cand) + 1L
    expect_true(all(grp[p] == grp))
  }
})

test_that("permute preserves the number of positives within each stratum", {
  set.seed(3)
  grp <- rep(1:8, each = 4)
  y   <- rep(c(1, 1, 0, 0), times = 8)

  cand <- find_candidates(strata_features(grp), upper = 0, lower = 0, as_abs = TRUE)

  observed <- tapply(y, grp, sum)

  for (i in 1:25) {
    p <- permute(cand) + 1L
    expect_equal(as.numeric(tapply(y[p], grp, sum)), as.numeric(observed))
  }
})

test_that("permute spreads draws across candidates rather than fixing one", {
  set.seed(131)
  grp  <- sample(rep(1:20, each = 10))
  cand <- find_candidates(strata_features(grp), upper = 0, lower = 0, as_abs = TRUE)

  perm <- do.call(rbind, replicate(300, permute(cand), simplify = FALSE))

  # Row 1 should not land on the same partner every single time
  tab <- prop.table(table(perm[, 1]))
  expect_gt(length(tab), 1L)
  expect_lt(max(tab), 0.9)
})
