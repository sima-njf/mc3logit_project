#' Conditional Logit Log-likelihood
#'
#' Computes the exact conditional log-likelihood for a single matched set
#' (stratum) by brute-force enumeration of all `choose(n, n1)` case/control
#' assignments. Useful as a reference implementation to validate
#' [survival::clogit()] and [clogit_perm()] on small strata.
#'
#' @param y Binary vector of length `n`. Response (1 = case, e.g. fired the
#'   weapon).
#' @param x Numeric matrix of size `n x k`. Features.
#' @param beta Numeric vector of size `k`. Coefficients.
#' @param n1 Integer. Number of cases in the stratum. Defaults to `sum(y)`.
#'
#' @return The log-likelihood of that single matched set. Strata with no
#'   variation in `y` (all cases or all controls) are uninformative and
#'   contribute `0` to the conditional log-likelihood.
#'
#' @examples
#' set.seed(1)
#' x <- cbind(rnorm(4))
#' y <- c(1, 0, 0, 0)
#' clogit_loglike(y, x, beta = 0.5)
#'
#' @export
clogit_loglike <- function(y, x, beta, n1 = sum(y)) {

  n <- length(y)

  if (n1 == n | n1 == 0)
    return(0)

  x <- cbind(x)

  ans <- sum(x[which(y == 1), ] %*% beta)

  sets <- utils::combn(seq_len(n), n1, simplify = FALSE)

  tmp <- 0
  for (s in sets)
    tmp <- tmp + exp(sum(x[s, ] %*% beta))

  ans - log(tmp)

}
