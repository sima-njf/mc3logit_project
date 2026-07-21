#' Print method for clogit_perm
#' @param x An object of class [clogit_perm].
#' @param odds Logical scalar. When `TRUE` it will print odds ratios.
#' @param labels A named list for alternative labels for the model terms.
#' @param out Character scalar. When `"ascii"` it will print for screen, otherwise,
#' it will print for LaTeX.
#' @param ... Ignored.
#' @export
#' @param odds Logical scalar. When TRUE it prints the odds ratios.
#' @param labels Named vector. Changes the labels of the model.
#' @importFrom stats coef confint cov
print.clogit_perm <- function(x, odds = TRUE, labels = NULL, out = "ascii", ...) {

  cis <- stats::confint(x, ...)

  space_fmt <- if (out == "ascii") {
    c("** ", "*  ", "   ", "< 0.01", "  %.2f", "\n")
  } else {
    c(
      "**\\hphantom{*}",
      "*\\hphantom{**}",
      "\\hphantom{***}",
      "$< 0.01$",
      "$\\hphantom{< }%.2f$",
      "\\\\\n"
    )
  }

  dat <- cbind(Coef = coef(x), cis, pval = x$pvals)
  if (odds)
    dat[,1:3] <- exp(dat[,1:3])

  if (!is.null(labels))
    rownames(dat) <- labels[rownames(dat)]

  # Checking the max rowname
  maxtit <- max(nchar(rownames(dat)))
  main_txt <- if (out == "ascii") {
    paste(sprintf("%%%ds", maxtit), " %9.2f%s [%5.2f, %5.2f] %s")
  } else  {
    paste(sprintf("%%%ds", maxtit), "& $%9.2f^{%s}$ & $[%5.2f, %5.2f]$ & %s")
  }

  dat <- sprintf(
    main_txt,
    rownames(dat),
    dat[,"Coef"],
    ifelse(dat[,4] <= .01, "***",
           ifelse(dat[,4] <= .05, space_fmt[1],
                  ifelse(dat[,4] <= .1, space_fmt[2], space_fmt[3]))),
    dat[,2],
    dat[,3],
    ifelse(dat[,4] <= .01, space_fmt[4], sprintf(space_fmt[5],dat[,4]))
  )

  # Dealing with others
  gof.names   <- c("N events", "N perm", "N", "AIC", "BIC")
  gof         <- c(x$fit$nevent, nrow(x$coefs), x$fit$n, stats::AIC(x$fit), stats::BIC(x$fit))
  cat("\nCONDITIONAL LOGIT (WITH PERMUTATION)\n")
  cat(sprintf("%10s: %d", gof.names[1:3], gof[1:3]), sep = "\n")
  cat(sprintf("%10s: %.2f", gof.names[4:5], gof[4:5]), sep = "\n")
  cat(sprintf("MODEL PARAMETERS (%s):\n", ifelse(odds, "odds", "betas")))
  cat(paste(dat, collapse = space_fmt[6]))
  cat("\n")
  invisible(x)

}

approx_sd <- function(b, pval) {

  f <- function(s) {
    p <- pnorm(b, mean = 0, sd = s)
    p <- ifelse(p > .1, 1 - p, p)
    (pval - p)^2
  }

  stats::optim(
    par = 1, fn = f, control = list(fnscale = -1),
    method = "Brent",
    lower = .Machine$double.eps,
    upper = .Machine$double.xmax
    )
}

#' Plot method for [clogit_perm] objects
#' @export
#' @param x An object of class [clogit_perm].
#' @param y Ignored
#' @param level Passed to [stats::confint()].
#' @param col Vector of colors for the model terms.
#' @param args_points List of arguments passed to [graphics::points()]
#' @param args_arrows List of arguments passed to [graphics::arrows()]
#' @param labels a named list with alternative labels for the model terms.
#' @param odds See [confint.clogit_perm].
#' @param which. See [confint.clogit_perm].
#' @param ... Ignored
#' @importFrom graphics points arrows plot.new plot.window abline axis text
plot.clogit_perm <- function(
  x,
  y             = NULL,
  level         = .95,
  col           = 1:length(stats::coef(x)),
  args_points   = list(pch = 19, cex = 1.5),
  args_arrows   = list(lwd = 2, code=3, angle=90, length = .1),
  labels        = NULL,
  odds          = FALSE,
  which.        = "coef",
  ...
) {

  ci     <- stats::confint(x, level = level, which. = which.)
  betas  <- stats::coef(x)

  if (odds) {
    ci[]    <- exp(ci)
    betas[] <- exp(betas)
  }

  ranges <- range(ci)
  ranges_extended <- ranges + c(- diff(ranges)*.75, 0)

  # Making sure the CIs are CIs
  ci[,1] <- ci[,1] - diff(ranges_extended)/200
  ci[,2] <- ci[,2] + diff(ranges_extended)/200

  # Reversing order
  betas <- rev(betas)
  ci    <- ci[nrow(ci):1, , drop=FALSE]

  ylims <- as.factor(rownames(ci))

  graphics::plot.new()
  graphics::plot.window(
    xlim = ranges_extended,
    ylim = c(1, length(ylims) + .5)
  )
  graphics::abline(h = 1:9, lwd = 1, col = "lightgray", lty="dashed")
  graphics::abline(v = ifelse(odds, 1, 0), lty=2, lwd=1)
  do.call(
    graphics::arrows,
    c(
      args_arrows,
      list(
        x0 = ci[,1],
        x1 = ci[,2],
        y0 = 1:length(ylims),
        # y1 = as.integer(ylims),
        col = col
      )
    )
  )

  do.call(
    graphics::points,
    c(
      args_points,
      list(x = betas, y = 1:length(ylims), col = col)
    )
  )


  labs <- if (!is.null(labels))
    labels[as.character(ylims)]
  else
    as.character(ylims)

  graphics::text(
    x      = ranges_extended[1],
    y      = 1:length(ylims) + .25,
    labels = labs,
    pos    = 4,
    offset = -.5
  )

  loc <- pretty(ranges)
  graphics::axis(1, labels = loc, at=loc)

}
