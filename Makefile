build:
	Rscript -e 'Rcpp::compileAttributes();roxygen2::roxygenize()' && \
		cd .. && R CMD build rpackage/
install:
	$(MAKE) build && R CMD INSTALL ../mc3logit_*
