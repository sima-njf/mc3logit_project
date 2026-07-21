#' Simulate Police Force Events
#'
#' This function generates data similar to that featured in the paper. Events
#' are drawn at random, as the number of officers per event. The outcome variable,
#' whether the officer points his gun or not, is drawn sequentially as a poisson
#' process.
#'
#' @param nevents,nofficers Integers. Number of events and officers to simulate.
#' @param min_per_event,max_per_event Integers. Lower and upper bounds for the
#' number of officers in the event.
#' @param min_year,max_year Integers. Lower and upper bounds for the number
#' of years of experience of the officers.
#' @param min_rate,max_rate Doubles. Lower and upper bounds for the reaction
#' rates (see details).
#' @param par_officer_female,par_officer_years,par_exposure_event,par_exposure_prev,par_event_violence,par_officer_fe
#' Doubles. Parameters (coefficients) for the logistic probabilities.
#' @param seed Integer. Seed for the pseudo-number generation.
#' @param nsims Integer. When greater than 1, the program will simulate multiple
#' datasets, using the same set of parameters and individual's features, and
#' append the corresponding results to the end of data frame.
#'
#' @details
#' The simulation process goes as follow:
#' 1. The officers are simulated.
#'
#'    \deqn{Female ~ Bernoulli(0.5)}
#'
#'    \deqn{Action rate ~ Unif(min_rate, max_rate)}
#'
#'    \deqn{Years of experience ~ Discrete Unif[min_years, max_year]}
#'
#' 2. Events are simulated, each event has
#'
#'    \deqn{nofficers ~ Discrete Unif[min_per_event, max_per_event]}
#'
#'    Once the event is done, a sequence of reaction is given by each officers'
#'    action rate (Poisson process). Whether an officer points or not is set by
#'    a logistic model
#'
#'    \deqn{
#'    point ~ logis(female + years of experience + has any pointed? + previous exposure)
#'    }
#'
#'    The corresponding parameters are as specified by the user. Events are simulated
#'    one at a time.
#' @returns
#' A data frame with the following columns
#' - `officerid` Id of the police officer
#' - `female` 1 if it is female
#' - `years` years of experience
#' - `fixed_effect` officers' propensity to point the gun
#' - `incidentid` Incident id
#' - `violence_level` Violence level of the event
#' - `response_time` Time the officer took to respond
#' - `first` Whether the officer was the first to act or not
#' - `exposed` Whether the officer was exposed in the previous event
#' - `pointed000001 ... pointed[nsims]` Integer vectors indicating whether the
#' officer pointed the gun or not.
#'
#' Each row represents one report per officer involved in the event.
#' @export
#' @examples
#' x <- sim_events(1000, 400)
#'
#' x <- sim_events(
#'   20000,200,
#'   par_officer_female = -.5,
#'   par_officer_years = -.5,
#'   par_exposure_event = -.5,
#'   par_event_violence = 1,
#'   par_exposure_prev = .25,
#'   par_officer_fe = 1,
#'   seed = 445
#' )
#'
#' # Full model knowing latent variables
#' ans <- glm(
#'   pointed000001 ~ -1+female + years + exposed + I(-first) + fixed_effect +
#'   violence_level, data = x, family = binomial()
#' )
#'
#' summary(ans)
sim_events <- function(
  nevents,
  nofficers,
  min_per_event      = 1,
  max_per_event      = 5,
  min_year           = 0,
  max_year           = 10,
  min_rate           = 5,
  max_rate           = 5,
  par_officer_female = -.5,
  par_officer_years  = -.5,
  par_exposure_event = 0,
  par_exposure_prev  = .5,
  par_event_violence = 1,
  par_officer_fe     = 1,
  nsims              = 1,
  seed               = sample.int(.Machine$integer.max, 1)
) {

  ans <- sim_events_cpp(
    nevents            = nevents,
    nofficers          = nofficers,
    min_per_event      = min_per_event,
    max_per_event      = max_per_event,
    min_year           = min_year,
    max_year           = max_year,
    min_rate           = min_rate,
    max_rate           = max_rate,
    par_officer_female = par_officer_female,
    par_officer_years  = par_officer_years,
    par_exposure_event = par_exposure_event,
    par_exposure_prev  = par_exposure_prev,
    par_event_violence = par_event_violence,
    par_officer_fe     = par_officer_fe,
    nsims              = nsims,
    seed               = seed
  )

  ans <- do.call(cbind, ans)
  colnames(ans) <- c(
    "officerid",
    "female",
    "years",
    "fixed_effect",
    "incidentid",
    "violence_level",
    "response_time",
    "first",
    "exposed",
    sprintf("pointed%06i", 1:nsims)
  )

  as.data.frame(ans)
}


#' @export
#' @param event_id,officer_id Integer vectors. Values for the incident and
#' officer id.
#' @param officer_female,officer_years Logical and integer vectors, respectively. Features
#' of the officers.
#' @param officer_fe,officer_rate Double vectors, more features of the officers.
#' @rdname sim_events
#' @details
#' In the case of `sim_events2`, the user can pass predefined events and
#' officers and use those to simulate each officers' reactions.
#' @importFrom Rcpp sourceCpp
#' @useDynLib mc3logit, .registration = TRUE
sim_events2 <- function(
  event_id,
  officer_id,
  officer_female,
  officer_years,
  officer_fe         = rep(0, length(event_id)),
  officer_rate       = rep(1, length(event_id)),
  par_officer_female = -.5,
  par_officer_years  = -.5,
  par_exposure_event = .5,
  par_exposure_prev  = .5,
  par_event_violence = 1,
  par_officer_fe     = 1,
  nsims              = 1,
  seed               = sample.int(.Machine$integer.max, 1)
) {

  ans <- sim_events2_cpp(
    event_id           = event_id,
    officer_id         = officer_id,
    officer_female     = officer_female,
    officer_rate       = officer_rate,
    officer_fe         = officer_fe,
    officer_years      = officer_years,
    par_officer_female = par_officer_female,
    par_officer_years  = par_officer_years,
    par_exposure_event = par_exposure_event,
    par_exposure_prev  = par_exposure_prev,
    par_event_violence = par_event_violence,
    par_officer_fe     = par_officer_fe,
    nsims              = nsims,
    seed               = seed
  )

  ans <- do.call(cbind, ans)
  colnames(ans) <- c(
    "officerid",
    "female",
    "years",
    "fixed_effect",
    "incidentid",
    "violence_level",
    "response_time",
    "first",
    "exposed",
    sprintf("pointed%06i", 1:nsims)
  )

  as.data.frame(ans)
}
