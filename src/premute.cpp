#include <Rcpp.h>
using namespace Rcpp;

inline bool is_within_window(
    const IntegerMatrix & x,
    const IntegerVector & upper,
    const IntegerVector & lower,
    const LogicalVector & as_abs,
    int i, int j
) {

  unsigned int k = x.ncol();
  for (unsigned int f = 0u; f < k; ++f) {

    int diff = x(i, f) - x(j, f);
    if (as_abs[f])
      diff = abs(diff);

    if (diff < lower[f])
      return false;
    else if (diff > upper[f])
      return false;

  }

  return true;

}

//' Find permutation candidates for each row
//' @param features An integer matrix of features to be match (depending on
//' the window).
//' @param upper,lower Integer vector indicating, for each feature, the
//' upper and lower bounds.
//' @param as_abs Logical vector of length equal to the number of features.
//' When `TRUE` it indicates that the difference should be taken in absolute terms.
//' @details
//' Matches (or permutation candidates) are identified depending on the rule
//' specified by `upper` and `lower`. For feature `k`, the match between `(i,j)` is possible if
//'
//' - If `window[k] < 0` and `features[i, k] != features[j, k]`
//' - If `abs(features[i, k] - features[j, k]) <= window[k]`
//'
//' @returns
//' A list of integer vectors (starting from zero) indicating the position of
//' the potential permutation.
//' @export
//' @importFrom Rcpp sourceCpp
// [[Rcpp::export]]
std::vector< std::vector<int> > find_candidates(
    const IntegerMatrix & features,
    const IntegerVector & upper,
    const IntegerVector & lower,
    const LogicalVector & as_abs
) {

  int n = features.nrow();
  int k = features.ncol();

  if (upper.size() != k)
    stop("The number of features does not match the length of the -upper- vector.");
  if (lower.size() != k)
    stop("The number of features does not match the length of the -lower- vector.");
  if (as_abs.size() != k)
    stop("The number of features does not match the length of the -lower- vector.");

  std::vector< std::vector< int > > candidates(n);

  for (int i = 0u; i < n; ++i) {

    for (int j = 0u; j < i; ++j) {

      if (is_within_window(features, upper, lower, as_abs, i, j)) {

        // printf("Annotating (%i,%i)!\n", i, j);
        candidates[i].push_back(j);
        candidates[j].push_back(i);

      }

    }

  }

  return candidates;
}




inline unsigned int sample_n(unsigned int n) {
  return (floor(unif_rand() * n));
}

//' Random permutation of the data as a function of `find_candidates`
//' @param candidates An integer list as that resulting from [find_candidates()].
//' @returns
//' An integer vector (indexed from 0) with the permuted version of the data.
//' @export
// [[Rcpp::export]]
std::vector< unsigned int > permute(
    const std::vector< std::vector< unsigned int > > & candidates
) {

  std::vector< unsigned int > idx(candidates.size());
  std::iota(idx.begin(), idx.end(), 0u);
  std::vector< bool > picked(idx.size(), false);

  std::vector< unsigned int > res(idx);

  // Permuting until idx is of size 0
  int nleft = idx.size();
  while (nleft > 0) {

    // Selecting from idx
    unsigned int i = sample_n(nleft);

    // Was it picked as j in a previous run?
    if (picked[idx[i]]) {
      idx[i] = idx[--nleft];
      continue;
    }

    // If empty, then remove and go to the next
    unsigned int j;
    if (candidates[idx[i]].size() == 0u) {

      picked[idx[i]] = true;
      idx[i]         = idx[--nleft];
      continue;

    } else if (candidates[idx[i]].size() == 1u) {

      j = candidates[idx[i]][0u];

      // Was it picked before?
      if (picked[j]) {

        picked[idx[i]] = true;
        idx[i]         = idx[--nleft];
        continue;

      }

    } else {

      // Temp copy that can be discarded
      std::vector< unsigned int > tmpc(candidates[idx[i]]);
      unsigned int nleft_j = tmpc.size();

      bool pending = true;
      while (pending) {

        j = sample_n(nleft_j);
        if (picked[tmpc[j]])
          tmpc[j] = tmpc[--nleft_j];
        else { // Case in which

          pending = false;
          j       = tmpc[j];
          break;

        }

        if (nleft_j == 0u)
          break;

      }

      // Was not able to find anything
      if (pending) {

        picked[idx[i]] = true;
        idx[i]         = idx[--nleft];
        continue;

      }
    }

    // Applying the permutation
    res[idx[i]] = j;
    res[j]      = idx[i];

    // "Removing" from the list
    picked[idx[i]] = true;
    picked[j]      = true;
    idx[i]         = idx[--nleft];

  }

  return res;

}
