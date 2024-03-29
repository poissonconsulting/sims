#' Simulated Datasets
#'
#' Gets the simulated datasets as an [nlist::nlists_object()].
#' There is no guarantee that all the datasets will fit in memory.
#'
#' @inheritParams params
#' @return An [nlist::nlists_object()] of the simulated datasets.
#' @export
#' @examples
#' set.seed(10)
#' sims_simulate("a <- runif(1)",
#'   nsims = 10L, path = tempdir(),
#'   exists = NA, ask = FALSE
#' )
#' library(nlist)
#' sims_data(tempdir())
sims_data <- function(path = ".") {
  data_files <- sims_data_files(path)
  nlists <- lapply(file.path(path, data_files), readRDS)
  as_nlists(nlists)
}
