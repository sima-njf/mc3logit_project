---
title: 'mc3logit: Permutation-based inference for matched case-control conditional logit in R'
tags:
  - R
  - permutation tests
  - conditional logistic regression
  - matched case-control
  - criminology
  - resampling
authors:
  - name: Sima Najafzadeh
    orcid: 0009-0002-6253-2910
    corresponding: true
    affiliation: 1
  - name: George G. Vega Yon
    orcid: 0000-0002-3171-0844
    affiliation: 1
affiliations:
  - name: University of Utah, USA
    index: 1
date: 26 July 2026
bibliography: paper.bib
---

# Summary

`mc3logit` is an R package for fitting conditional logistic regression to
matched case-control data and obtaining **permutation-based** p-values and
confidence intervals in place of the usual asymptotic ones. Matched
case-control designs arise whenever several units share an event and only some
of them act: officers responding to the same incident, patients within a
matched stratum, animals within a litter. Conditional logistic regression
handles the matching by conditioning the stratum out of the likelihood, but the
Wald standard errors it reports lean on large-sample approximations that are
poorly justified when strata are small or outcomes are rare, which is the
common case in practice.

Rather than trusting those approximations, `mc3logit` reassigns the outcome
uniformly at random *within* each matched set, refits the model, and builds an
empirical null distribution for every coefficient. The package also supplies
simulators for matched case-control event data and a helper for constructing
running "exposure" covariates from a longitudinal event log, so that a full
analysis, including design-specific power studies, can be carried out from a
single package.

# Statement of need

Applied researchers working with matched case-control data face a gap between
the model they want and the inference they can trust. `survival::clogit`
[@therneau2000] fits the model well, but its Wald intervals assume asymptotics
that many real designs do not satisfy: matched sets of two to five units, and
outcomes occurring in a small minority of records. In this regime the
likelihood is often close to separable within strata, and reported standard
errors can be badly optimistic.

Permutation inference is the textbook remedy, but implementing it correctly for
this design is subtle. The permutation must respect the matching: it has to
shuffle outcomes strictly within strata, and it must preserve the number of
positive cases each stratum began with, since that count is exactly what the
conditional likelihood conditions on. Getting this wrong does not produce an
error message; it produces a reference distribution of the wrong width and
p-values that are quietly miscalibrated. Researchers who assemble this by hand,
as is common, have no easy way to detect the mistake.

`mc3logit` packages the correct construction behind an interface identical to
`clogit`, adding a single `nperm` argument. It targets applied quantitative
researchers in criminology, epidemiology, and the social sciences who already
think in terms of matched designs and want defensible inference without writing
resampling code themselves. The approach follows @ridgeway2016, who used
permutation inference on exactly this kind of matched-officer data.

# State of the field

R has strong general-purpose permutation tooling, but none of it covers this
design. `coin` [@hothorn2008] implements a broad, principled class of
permutation tests through conditional inference, yet it is organised around
independence tests rather than around refitting a conditional logit and
collecting coefficients. `permuco` [@frossard2021] provides permutation tests
for regression and ANOVA, including residual-permutation schemes for nuisance
covariates, but targets linear models and signal comparison rather than
conditional logistic regression with strata. `survival` [@therneau2000] fits
the model of interest but offers only asymptotic inference.

| Package | Fits conditional logit | Permutation inference | Respects matched strata | Simulators for the design |
|:--|:--:|:--:|:--:|:--:|
| `mc3logit` | yes | yes | yes | yes |
| `survival` | yes | no | yes | no |
| `coin` | no | yes | partial | no |
| `permuco` | no | yes | no | no |

The gap `mc3logit` fills is therefore narrow but real: the combination of a
conditional logit fit, a permutation scheme valid for matched sets, and
data-generating tools for studying that combination.

# Software design

The user-facing function, `clogit_perm()`, takes a `survival`-style formula
with a `strata()` term plus `nperm`. It fits the baseline model once, then
draws `nperm` permutations and refits, distributing refits across cores via
`parallel`. Coefficients from failed refits are recorded rather than silently
dropped, so degenerate permutations remain auditable.

Two design decisions are worth stating explicitly. First, each draw is a
**uniform shuffle of row positions within each stratum**. This preserves every
stratum's positive count automatically and, crucially, leaves any given row in
place with probability $1/m$ for a stratum of size $m$. A scheme that always
moves every row is not a random permutation but a fixed relabelling; for the
two-row strata that dominate matched case-control data it is deterministic, and
it collapses the reference distribution. Second, following @knijnenburg2009, a
p-value that rounds to zero is replaced by the pseudo-count $1/\texttt{nperm}$,
since the observed arrangement belongs to the reference distribution and the
true p-value can never be exactly zero.

Simulation and exposure routines are implemented in C++ through `Rcpp`
[@eddelbuettel2011]. `sim_events()` and `sim_events2()` generate matched
case-control data from known coefficients, and their `nsims` argument produces
many replicate outcomes over a fixed design, which is what makes size and power
studies inexpensive. `exposure_dyn()` computes running direct and indirect
exposure counts from an event log without look-ahead or self-counting.

A vignette shipped with the package uses these tools to measure the method's
own behaviour: under a complete null the permutation p-values are approximately
uniform and the rejection rate is close to nominal.

# Limitations

Because `clogit_perm()` permutes the raw outcome, its reference distribution is
built under the *complete* null, in which no covariate is associated with the
outcome, rather than the *partial* null actually being tested, in which the
covariate of interest has no effect while others may. When a nuisance covariate
carries substantial signal the reference distribution is too narrow and the
test is anti-conservative. The package documents this in a dedicated validation
vignette, quantifies it by simulation, and recommends cross-checking against
the Wald p-value of the baseline fit in that situation. Residual-permutation
schemes in the spirit of @freedman1983 would address it and are the natural
direction for future work.

# Research impact statement

The permutation approach implemented here underlies published work on the
social transmission of police firearm use [@ouellet2022], and follows the
matched case-control design of @ridgeway2016. The code originated as analysis
scripts supporting that line of research; `mc3logit` generalises it into a
documented, tested package so that the same inference is available to other
matched case-control studies without reimplementation. Beyond criminology, the
design is standard in epidemiology and animal studies, where small strata and
rare outcomes make asymptotic intervals equally fragile.

# AI usage disclosure

Generative AI assistance (Anthropic's Claude) was used during preparation of
this software for packaging, test authoring, documentation and vignette
drafting, and for diagnosing defects, including a permutation scheme that was
not sampling uniformly and a link-time defect that crashed the simulators. All
statistical claims, simulation results and citations in this paper were
verified by the authors, and all AI-suggested changes were reviewed before
inclusion.

# Acknowledgements

`mc3logit` grew out of the `use_of_force` project by George G. Vega Yon. We
thank the maintainers of `survival` and `Rcpp`, on which the package depends.

# References
