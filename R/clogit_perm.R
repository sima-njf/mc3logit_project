#' Conditional logit with permutation
#' @param nperm Integer. Number of permutations
#' @param formula,data,... Parameters passed to [survival::clogit()]
#' @param ncpus Integer. Number or cores.
#' @param parallel_args Parameters passed to [parallel::makeCluster()].
#' @export
#' @importFrom survival clogit
#' @importFrom stats terms
#' @details
#' In the case that p-values go to zero, these are replaced with the
#' pseudo-count, this is, `1/nperm` (Knijnenburg et al., 2009.)
#' @references
#' Knijnenburg, T. A., Wessels, L. F. A., Reinders, M. J. T., & Shmulevich, I. (2009).
#' Fewer permutations, more accurate P-values. Bioinformatics, 25(12), 161–168.
#' \doi{10.1093/bioinformatics/btp211}
clogit_perm <- function(
  nperm = 1000,
  formula,
  data,
  ...,
  ncpus = parallel::detectCores(),
  parallel_args = list()
  ) {

  # Capturing strata variable
  fterms <- stats::terms(formula)

  strata_term <- attr(fterms, "term.labels")
  strata_term <- strata_term[which(grepl("^strata[(]", strata_term))]

  if (length(strata_term) != 1)
    stop("There should be one -strata()- term in the formula.", call. = FALSE)

  strata_term <- gsub("^strata[(]|[)]$", "", strata_term)

  if (!(strata_term %in% colnames(data)))
    stop("The term \"", strata_term, "\" is not present in -dat-.")

  # Finding the dependent variable
  if (!attr(fterms, "response"))
    stop("No dependent variable in this model.", call. = FALSE)

  depvar <- rownames(attr(fterms, "factors"))[1L]

  # Finding the permutations
  groups <- as.integer(as.factor(data[, strata_term]))
  if (any(is.na(groups)))
    stop("There are missings in the strata() term.")

    # Finding candidates
  groups <- cbind(groups)
  candidates <- find_candidates(
    features = groups,
    upper    = 0,
    lower    = 0,
    as_abs   = TRUE
  )

  # Generating the permutations
  ORD <- replicate(nperm, permute(candidates) + 1L, simplify = FALSE)

  # Baseline model
  model0 <- survival::clogit(formula = formula, data = data, ...)

  # Preparing the permutation
  coefs <- if (ncpus > 1L) {
    cl <- do.call(
      parallel::makeCluster,
      c(list(spec = ncpus), parallel_args)
    )
    parallel::clusterEvalQ(cl, library(survival))
    on.exit(parallel::stopCluster(cl))
    parallel::parLapply(cl, ORD, function(ord, formula., data., ..., depvar.) {

      # Permuting the dependent variable
      data.[, depvar.] <- data.[, depvar.][ord]

      # Fitting the survival model
      ans <- tryCatch(
        stats::coef(survival::clogit(formula = formula., data = data., ...)),
        error = function(e) e
      )

      if (inherits(ans, "error"))
        return(as.character(ans))

      ans

    }, formula. = formula, data. = data, ..., depvar. = depvar)
  } else {

    lapply(ORD, function(ord, formula., data., ..., depvar.) {

      # Permuting the dependent variable
      data.[, depvar.] <- data.[, depvar.][ord]

      # Fitting the survival model
      ans <- tryCatch(
        stats::coef(survival::clogit(formula = formula., data = data., ...)),
        error = function(e) e
      )

      if (inherits(ans, "error"))
        return(as.character(ans))

      ans

    }, formula. = formula, data. = data, ..., depvar. = depvar)

  }

  # Checking errors
  is_err <- sapply(coefs, inherits, what = "character")

  # Building a list
  coefs <- do.call(rbind, coefs[!is_err])

  # Calculating confidence intervals and pvals
  pvals   <- rowMeans(t(coefs) < stats::coef(model0))
  pvals[] <- ifelse(pvals < .5, pvals, 1 - pvals)*2

  # Minimum p-value (lower-bound):
  # p-values can never be zero since the observed data is included in the
  # distribution. Instead, we replace the zero p-values with a pseudo-count
  # 1/N replicates. (see )
  pvals[pvals < .Machine$double.xmin] <- 1/nperm

  structure(
    list(
      pvals      = pvals,
      fit        = model0,
      coefs      = coefs,
      candidates = candidates,
      formula    = formula,
      errors     = data.frame(id = which(is_err), msg = coefs[which(is_err)], stringsAsFactors = TRUE)
      ),
    class = "clogit_perm"
  )

}

#' @export
coef.clogit_perm <- function(object, ...) stats::coef(object$fit)

#' @export
vcov.clogit_perm <- function(object, ...) cov(object$coefs)

#' @export
formula.clogit_perm <- function(x, ...) x$formula

#' @export
nobs.clogit_perm <- function(object, ...) {
  stats::nobs(object$fit)
}

#' Confidence interval for CLogit
#' @param object An object of class [clogit_perm]
#' @param parm Integer vector. Indicates which parameters to include in the
#' output.
#' @param level Numeric. Level (see [stats::confint]).
#' @param which. When `"coef"`, it will generate the confidence interval for the
#' parameter estimates, otherwise it generates the confidence interval of the reference
#' distribution.
#' @param sigma_perm Logical scalar. When `TRUE`, uses the permutation based
#' standard errors for computing the CI (only used when `which. = "coef"`)
#' @param ... Ignored.
#' @seealso clogit_perm
#' @export
confint.clogit_perm <- function(
    object, parm, level = 0.95, which. = "coef",
    sigma_perm= FALSE,
    ...
    ) {

  if (missing(parm))
    parm <- 1:ncol(object$coefs)

  if (which. == "coef") {

    coe   <- coef(object)
    # df    <- stats::nobs(object) - length(coe)
    sigma <- if (sigma_perm)
      sqrt(diag(stats::vcov(object)))
    else
      abs(coe/qnorm(object$pvals/2)) # abs(coe/qt(object$pvals/2, df = df))
    a     <- (1 - level)/2
    pm    <- qnorm(p = a) * sigma # qt(p = a, df = df) * sigma

    ans <- cbind(coe + pm, coe - pm)
    colnames(ans) <- sprintf("%.1f %%", c(a, 1 - a)*100)
    ans

  } else {

    t(apply(
      object$coefs[, parm, drop=FALSE], 2,
      stats::quantile,
      probs = c(0, 1) + c(1, -1)*(1 - level)/2
      ))

  }

}

#' #' Extract components for texreg objects
#' #' @export
#' #' @param model An object of class [clogit_perm]
#' #' @param level Double. level for the CI.
#' #' @param odds Logical, when `TRUE`, returns odds-ratios.
#' #' @param ... Further arguments, including `ci.force`.
#' #' @importFrom texreg extract
#' #'
#' extract.clogit_perm <- function(
#'   model,
#'   level = 0.95,
#'   odds = TRUE,
#'   # include.aic = TRUE,
#'   # include.bic = TRUE,
#'   # include.loglik = TRUE,
#'   # include.nnets = TRUE,
#'   # include.offset = TRUE,
#'   # include.convergence = TRUE,
#'   # include.timing      = TRUE,
#'   ...
#' ) {
#'
#'   # Capturing arguments
#'   dots <- list(...)
#'
#'   coefficient.names <- colnames(model$coefs)
#'   coefficients      <- stats::coef(model)
#'   standard.errors   <- sqrt(diag(stats::vcov(model)))
#'   significance      <- model$pvals
#'
#'   # GOF
#'   gof.names   <- c("N events", "N perm", "N", "AIC", "BIC")
#'   gof         <- c(model$fit$nevent, nrow(model$coefs), model$fit$n, stats::AIC(model$fit), stats::BIC(model$fit))
#'   gof.decimal <- c(FALSE, FALSE, FALSE, TRUE, TRUE)
#'
#'   # Confidence intervals,
#'   if (length(dots$ci.force) && dots$ci.force) {
#'     cis_l <- apply(model$coefs, 2, quantile, probs = c(0,1) + c((1-level)/2)*c(1,-1))
#'     cis_u <- cis_l[2,]
#'     cis_l <- cis_l[1,]
#'
#'   } else {
#'     cis_l <- numeric(0)
#'     cis_u <- numeric(0)
#'   }
#'
#'   if (odds) {
#'     coefficients <- exp(coefficients)
#'     cis_u <- exp(cis_u)
#'     cis_l <- exp(cis_l)
#'   }
#'
#'
#'   return(
#'     texreg::createTexreg(
#'       coef.names  = coefficient.names,
#'       coef        = coefficients,
#'       se          = standard.errors,
#'       pvalues     = significance ,
#'       gof.names   = gof.names,
#'       gof         = gof,
#'       gof.decimal = gof.decimal,
#'       ci.low      = cis_l,
#'       ci.up       = cis_u
#'     )
#'   )
#'
#' }
#'
#' setMethod(
#'   "extract", signature = className("clogit_perm", "njforce"),
#'   definition = extract.clogit_perm
#' )
