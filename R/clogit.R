#' Conditional Logit Log-likelihood
#'
#' Computes the conditional (fixed-effects) log-likelihood contribution of a
#' single matched set (stratum). Strata that are uninformative -- those in
#' which every unit acted, or none did -- contribute exactly zero and are
#' returned as such.
#'
#' @param y Binary vector of length `n`. Response.
#' @param x Numeric matrix of size `n x k`. Features.
#' @param beta Numeric vector of size `k`. Coefficients.
#' @param n1 Integer scalar. Number of positive cases in the stratum. Defaults
#' to `sum(y)`, which is what conditional logit conditions on.
#'
#' @return The log-likelihood of that event.
#'
#' @details
#' The likelihood conditions on the number of positive outcomes in the
#' stratum, so the denominator sums over all `choose(n, n1)` ways of assigning
#' `n1` positives among the `n` units. This is exact, and therefore only
#' practical for small strata -- the cost grows combinatorially with `n`.
#'
#' @examples
#' x <- cbind(c(0, 1))
#' y <- c(1, 0)
#'
#' # Equivalent to a two-unit conditional logit contribution
#' clogit_loglike(y, x, beta = 0.7)
#'
#' # Uninformative strata contribute nothing
#' clogit_loglike(c(1, 1), x, beta = 0.7)
#'
#' @seealso [clogit_perm()] for the model-fitting interface.
#' @export
clogit_loglike <- function(y, x, beta, n1 = sum(y)) {

  n <- length(y)

  if (n1 == n | n1 == 0)
    return(0)

  ans <- sum(x[which(y == 1), , drop = FALSE] %*% beta)

  sets <- utils::combn(seq_len(n), n1, simplify = FALSE)

  tmp <- 0
  for (s in sets)
    tmp <- tmp + exp(sum(x[s, , drop = FALSE] %*% beta))

  ans - log(tmp)

}
