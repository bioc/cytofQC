#' Read in a dataset and prepare it for analysis
#'
#' @param file.name A path to an .fcs file that contains CyTOF data or a 
#' \code{flowSet} object containing a single sample.
#' @param beads character vector that contains the names of all of the bead 
#' channels.
#' @param dna Character vector that contains the names of the DNA markers.
#' @param event_length Character vector of the event length variable.
#' @param viability Character vector of the permeability/viability markers.
#' @param gaussian Character vector that contains the names of the Gaussian 
#' Discrimination Parameters.
#' @param verbose Logical value indicating whether or not to print a summary of
#'   the technical channels identified in the data.
#'
#' @return A \code{SingleCellExperiment} that contains the information from
#' the CyTOF fcs file, the technical data that will be used to label 
#' the data, and other objects that are used to store information through
#' the labeling process. The objects are \code{DataFrame} objects that
#' are stored in the \code{colData} for the \code{SingleCellExperiment}. 
#' The objects are: 
#' \item{label}{A single variable \code{DataFrame} that will contain the
#' event label as determined by \code{cytofQC}. At this point, all events
#' are labeled "gdpZero" if \code{Event_length} or any of the Gaussian
#' parameters are zero and "cell" otherwise. These labels are changed during
#' later stages.}
#' \item{probs}{A \code{DataFrame} that contains the "probability" that an
#' event is a certain type. This is initialized as NA at 
#' this point and is filled in later on.}
#' \item{tech}{A \code{DataFrame} that contains the technical variables
#' used to determine the label of each event. The bead, DNA, and viability
#' variables have an arcsinh transform, Event_length is unchanged, and 
#' the Gaussian parameters have a log transform using \code{log1p}.}
#' \item{scores}{Scores are computed to determine how much an event looks
#' like a bead, debris, doublet, or dead cell. These scores are used 
#' to select a training dataset for the classification model, but they 
#' can be helpful for exploratory data analysis so they are provided in 
#' this \code{DataFrame}. At this stage they are initialized as NA and
#' values are added in later steps.}
#' \item{initial}{Initial classification of each event type is determined
#' using a mixture model and the event type score. The \code{initial}
#' object is a \code{DataFrame} that will hold this initial classification.
#' A training dataset for the event classification model is selected using 
#' this initial classification.}
#'
#' @details
#' The function returns a \code{SingleCellExperiment} that contains all of 
#' the original information from the fcs file. The data are imported using
#' \code{CATALYST} and then information is added to the \code{colData}
#' that will be used to determine labels for each event and to provide
#' additional information about the events that can be used for 
#' exploratory data analysis and to aid the user in labeling the data. 
#' The objects are all initialized at this point an values are filled 
#' in during later stages of the labeling process.
#' Note that the names from the fcs file are required as arguments 
#' to the \code{readCytof}. If you are not sure what those names are, 
#' there is some code in the example that shows how to import your 
#' data into a \code{SingleCellExperiment} using \code{prepData} from
#' \code{CATALYST} and look at the names. 
#'
#' @examples
#' library(CATALYST)
#' library(SingleCellExperiment)
#' data("raw_data", package = "CATALYST")
#' 
#' # Determine at the names of the bead, DNA, and viability channels in the 
#' # file. Names are 'Beads', 'DNA1', 'DNA2', 'cisPt1', 'cisPt2'.
#' tech <- prepData(raw_data)
#' rownames(tech) 
#' 
#' # Determine names of event length and Gaussian parameters
#' # names are 'Event_length', 'Center', 'Offset', 'Width', 'Residual'
#' names(int_colData(tech)) 
#' 
#' # read in the data for use with cytofQC
#' x <- readCytof(raw_data, beads = 'Beads', viability = c('cisPt1','cisPt2'))
#' 
#' @importFrom CATALYST prepData
#' @importFrom SingleCellExperiment int_colData
#' @export
readCytof <- function(file.name,
                      beads = c("Bead"),
                      dna = c("DNA1", "DNA2"),
                      event_length = "Event_length",
                      viability = "Live_Dead",
                      gaussian = c("Center", "Offset", "Width", "Residual"),
                      verbose = TRUE) {
    
    sce <- NULL
    try(sce <- CATALYST::prepData(file.name), silent = TRUE)
    if (is.null(sce)) {
        tmp <- flowCore::read.FCS(file.name, emptyValue = FALSE)
        test <- flowCore::keyword(tmp)
        for (i in seq_along(test)) {
            if (test[[i]] == " ") {
                test[[i]] <- "0"
            }  
        }
        flowCore::keyword(tmp) <- test
        sce <- CATALYST::prepData(tmp)
        rm(tmp)
    }
    
    bead_channels <- matrix(t(SummarizedExperiment::assay(sce, "exprs")[rownames(sce) %in% beads, ]),
                            nrow = ncol(SummarizedExperiment::assay(sce, "exprs")))
    if (ncol(bead_channels) == 1) {
        colnames(bead_channels) <- "Bead"
    } else {
        colnames(bead_channels) <- vapply(seq_len(ncol(bead_channels)), 
                                          FUN = function(i){ paste0('Bead',i) },
                                          FUN.VALUE = '')
    }
    
    dna_channels <- matrix(t(SummarizedExperiment::assay(sce, "exprs")[rownames(sce) %in% dna, ]),
                           nrow = ncol(SummarizedExperiment::assay(sce, "exprs")))
    if (ncol(dna_channels) == 1) {
        colnames(dna_channels) <- "DNA"
    } else {
        colnames(dna_channels) <- vapply(seq_len(ncol(dna_channels)), 
                                         FUN = function(i){ paste0('DNA',i) },
                                         FUN.VALUE = '')
    }
    
    perm_channels <- matrix(t(SummarizedExperiment::assay(sce, "exprs")[rownames(sce) %in% viability, ]),
                            nrow = ncol(SummarizedExperiment::assay(sce, "exprs")))
    if (ncol(perm_channels) == 1) {
        colnames(perm_channels) <- "Viability"
    } else {
        colnames(perm_channels) <- vapply(seq_len(ncol(perm_channels)), 
                                          FUN = function(i){
                                              paste0('Viability',i)},
                                          FUN.VALUE = '')
    }
    
    gauss <- log1p(as.matrix(int_colData(sce)[, names(int_colData(sce)) %in% 
                                                  c(event_length, gaussian)]))
    
    # Make sure names of Gaussian variables are standardized
    colnames(gauss)[grep(event_length, colnames(gauss))] <- "Event_length"
    colnames(gauss)[grep("enter", colnames(gauss), ignore.case = TRUE)] <- 
        "Center"
    colnames(gauss)[grep("off", colnames(gauss), ignore.case = TRUE)] <- 
        "Offset"
    colnames(gauss)[grep("res", colnames(gauss), ignore.case = TRUE)] <- 
        "Residual"
    colnames(gauss)[grep("wid", colnames(gauss), ignore.case = TRUE)] <- 
        "Width"
    
    if(verbose){
        # summary of channels found
        message('Bead channels (', ncol(bead_channels), '): ', 
                paste(rownames(sce)[rownames(sce) %in% beads], collapse = ', '),
                '\n', 
                'DNA channels (', ncol(dna_channels), '): ', 
                paste(rownames(sce)[rownames(sce) %in% dna], collapse = ', '), 
                '\n', 
                'Viability channels (', ncol(perm_channels), '): ', 
                paste(rownames(sce)[rownames(sce) %in% viability], collapse = ', '),
                '\n',
                'Gaussian parameters (', ncol(gauss), '): ', 
                paste(names(int_colData(sce))[names(int_colData(sce)) %in% 
                                                  c(event_length, gaussian)], 
                      collapse = ', '),
                sep = '')
        
    }
    
    labels <- rep("cell", nrow(gauss))
    sce$label <- ifelse(rowSums(gauss == 0) > 0, "gdpZero", labels)
    
    sce$probs <- S4Vectors::DataFrame(bead = rep(NA, nrow(gauss)), 
                                      debris = rep(NA, nrow(gauss)), 
                                      doublet = rep(NA, nrow(gauss)), 
                                      dead = rep(NA, nrow(gauss)))
    
    sce$tech <- S4Vectors::DataFrame(cbind(bead_channels, dna_channels, 
                                           perm_channels, gauss))
    
    sce$scores <- S4Vectors::DataFrame(beadScore = rep(NA, nrow(gauss)), 
                                       debrisScore = rep(NA, nrow(gauss)), 
                                       doubletScore = rep(NA, nrow(gauss)), 
                                       deadScore = rep(NA, nrow(gauss)))
    
    sce$initial <- S4Vectors::DataFrame(beadInitial = rep(0, nrow(gauss)), 
                                        debrisInitial = rep(0, nrow(gauss)), 
                                        doubletInitial = rep(0, nrow(gauss)), 
                                        deadInitial = rep(0, nrow(gauss)))
    
    sce
}
