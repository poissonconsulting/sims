#' Simulated Datasets
#' 
#' Gets the simulated datasets as an \code{\link[nlist]{nlists_object}}.
#' There is no guarantee that all the datasets will fit in memory.
#'
#' @param path A string of the path to the directory with the simulated data files.
#'
#' @return An \code{\link[nlist]{nlists_object}} of the simulated datasets.
#' @export
#' @examples 
#' set.seed(10)
#' sims_simulate("a ~ dunif(0,1)", nsims = 10L, path = tempdir(), exists = NA, ask = FALSE)
#' library(nlist)
#' sims_data(tempdir())
sims_data <- function(path = getOption("sims.path", ".")) {
  data_files <- sims_data_files(path)
  nlists <- lapply(file.path(path, data_files), readRDS)
  as.nlists(nlists)
}