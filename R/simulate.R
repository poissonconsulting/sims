#' Simulate Datasets
#' 
#' Simulates datasets using R or JAGS code. By defaults 
#' return the datasets as an \code{\link[nlist]{nlists_object}}.
#' If \code{path} is provided then the datasets are written to the directory 
#' as individual \code{.rds} files.
#' 
#' JAGS code is identified by the presence of '~' indicating a stochastic variable node.
#' Otherwise code is assumed to be R code and stochastic variable nodes 
#' are those where assignment is immediately succeeded 
#' by a call to one of the functions named in \code{rdists}.
#'
#' Both constants and parameters must be \code{\link[nlist]{nlist_object}s}
#' (or lists that can be coerced to such) .
#' The only difference between constants and parameters is that the values in 
#' constants are appended to the output data while the values in parameters 
#' are not.
#' Neither constants or parameters can include missing values nor can they 
#' have elements with the same name.
#' Elements which are not in code are dropped with a warning 
#' (unless \code{silent = TRUE} in which case the warning is suppressed).
#' 
#' Each set of simulated data set is written as a separate .rds file. 
#' The files are labelled \code{data0000001.rds}, \code{data0000002.rds},
#' \code{data0000003.rds} etc.
#' The argument values are saved in the hidden file \code{.sims.rds}.
#' 
#' sims compatible files are those matching the regular expression 
#' "^((data\\\\d\{7,7\})|([.]sims))[.]rds$".
#' 
#' Parallelization is accomplished using the future package.
#' The \code{progress} and \code{options} arguments
#' are both passed to \code{\link[furrr]{future_map}()}.
#'
#' @param code A string of the JAGS code to generate the data.
#' The JAGS code must not be in a data or model block.
#' @param constants An nlist object (or list that can be coerced to nlist) 
#' specifying the values of nodes in code. 
#' The values are included in the output dataset.
#' @param parameters An nlist object (or list that can be coerced to nlist) 
#' specifying the values of nodes in code. 
#' The values are not included in the output dataset.
#' @param monitor A character vector (or regular expression if a string) 
#' specifying the names of the nodes in code to include in the dataset.
#' By default all nodes are included.
#' @param stochastic A logical scalar specifying whether to monitor 
#' deterministic and stochastic (NA), only deterministic (FALSE) 
#' or only stochastic nodes (TRUE).
#' @param latent A logical scalar specifying whether to monitor 
#' observed and latent (NA), only latent (TRUE) 
#' or only observed nodes (FALSE).
#' @param nsims An integer between 1 and 1,000,000 specifying 
#' the number of data sets to simulate. By default 100 data sets are simulated.
#' @param path A string specifying the path to the directory to save the data sets in.
#' By default \code{path = NULL} the data sets are not saved but are returned 
#' as an nlists object.
#' @param exists A flag specifying whether the \code{path} directory should already exist.
#' If \code{exists = NA} it doesn't matter. If the directory already exists 
#' all sims compatible files are deleted.
#' otherwise an error is thrown.
#' @param rdists A character vector specifying the R functions to recognize as stochastic.
#' @param progress A flag specifying whether to print a progress bar.
#' @param options The future specific options to use with the workers.
#' @param ask A flag specifying whether to ask before deleting all sims compatible files.
#' @param silent A flag specifying whether to suppress warnings.
#'
#' @return By default an \code{\link[nlist]{nlists_object}} of the simulated data.
#' Otherwise if \code{path} it returns TRUE.
#' @seealso \code{\link{sims_rdists}()} and \code{\link[furrr]{future_options}()}
#' @export
#' @examples
#' set.seed(101)
#' sims_simulate("a ~ dunif(0, 1)", path = tempdir(), exists = NA, ask = FALSE)
sims_simulate <- function(code, 
                          constants = nlist::nlist(), 
                          parameters = nlist::nlist(), 
                          monitor = ".*",
                          stochastic = TRUE,
                          latent = FALSE,
                          nsims = getOption("sims.nsims", 100L), 
                          path = getOption("sims.path"),
                          exists = FALSE,
                          rdists = sims_rdists(),
                          progress = FALSE,
                          options = furrr::future_options(), 
                          ask = getOption("sims.ask", TRUE),
                          silent = FALSE) {
  if(is.list(constants) && !is.nlist(constants)) class(constants) <- "nlist"  
  if(is.list(parameters) && !is.nlist(parameters)) class(parameters) <- "nlist"

  if(is_chk_on()) {
    chk_string(code)
    chk_nlist(constants); chk_no_missing(constants)
    chk_nlist(parameters); chk_no_missing(parameters)
    chk_s3_class(monitor, "character"); chk_gt(length(monitor))
    chk_lgl(stochastic)
    chk_lgl(latent)
    chk_whole_number(nsims); chk_range(nsims, c(1, 1000000))
    if(!is.null(path)) chk_string(path)
    chk_flag(ask)
    chk_lgl(exists)
    chk_s3_class(rdists, "character"); chk_no_missing(rdists)
    chk_flag(progress)
    chk_s3_class(options, "future_options")
    chk_flag(silent)
  }
  nsims <- as.integer(nsims)

  code <- prepare_code(code)
 
  check_variable_nodes(code, constants, rdists)
  check_variable_nodes(code, parameters, rdists)

  if(!is.null(path)) create_path(path, exists, ask, silent)
  
  monitor <- set_monitor(monitor, code, stochastic, latent, 
                         rdists = rdists, silent = silent)
  
  generate_datasets(code, constants, parameters, 
                    monitor = monitor, 
                    nsims = nsims,
                    path = path, progress = progress, 
                    options = options)
}