#' Dynamic Exposure
#'
#' Computes dynamic exposure in a longitudinal dataset without double counting
#' individuals.
#'
#' @param id_indiv Integer vector. Ids of individuals
#' @param id_events Integer vector. Ids of the events (must have a temporal
#' mapping).
#' @param actions Integer vector. Any value greater than one is considered
#' to be an action (true).
#' @param offset Integer. Offset in terms of lead
#' @export
#' @return
#' A matrix with the following columns:
#' - cumsum Integer vector. Cumulative sum of the actions vector.
#' - exposure_i Integer vector. Indirect exposure.
#' - exposure_d Integer vector. Direct exposure.
#' - exposure_i_cum Integer vector. Cumulative indirect exposure.
#' - exposure_d_cum Integer vector. Cumulative direct exposure.
#' @examples
#' dat <- data.frame(
#'   event = c(1,1,1, 2,2,2, 3,3,3,3, 4,4,4,4),
#'   id    = c(1,2,3, 1,2,4, 2,3,4,5, 5,1,6,2),
#'   fired = c(1,1,1, 0,1,1, 0,1,0,1, 1,0,1,1)
#' )
#'
#' counts <- with(dat, exposure_dyn(
#'   id_indiv  = id,
#'   id_events = event,
#'   actions   = fired,
#'   offset    = 0
#' ))
#'
#' cbind(dat, counts)
exposure_dyn <- function(
  id_indiv,
  id_events,
  actions,
  offset = 1
) {

  # Generating order with time
  ord <- order(id_events)

  ans <- do.call(cbind, exposure_dyn_(
    id_indiv  = id_indiv[ord],
    id_events = id_events[ord],
    actions   = actions[ord],
    offset    = offset
  ))

  ans[order((1:nrow(ans))[ord]),]

}


set.seed(123)
x <- 1:10
y <- sample(10)

ord <- order(y)
y[ord]
y[ord][order(x[ord])] - y
