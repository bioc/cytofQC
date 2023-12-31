% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/initialBead.R
\name{initialBead}
\alias{initialBead}
\title{Preliminary bead classification}
\usage{
initialBead(x)
}
\arguments{
\item{x}{A \code{SingleCellExperiment} created with \code{\link{readCytof}}.}
}
\value{
A \code{SingleCellExperiment} that contains the bead score and the 
bead designation for each event. This information is stored in the 
\code{score} and \code{initial} objects in the colData for the 
\code{SingleCellExperiment}.
}
\description{
Preliminary bead classification
}
\details{
The beads are typically the first cell classification that is done. The
different event types are labeled iteratively so the \code{labels}
vector in the colData will contain all of the labels and 
probabilities computed up to this point. Only events that 
have a "cell" label can be assigned an initial event classification of
"bead". This function computes a score that assesses how much an event
looks like a bead and then fits a mixture model to assign each event 
a class of 1 for a bead, -1 for an event that is not a bead, or 0 
for undetermined or previously assigned to a different event type. 
The score is recorded in the \code{score} object in the colData and 
the initial classification is recorded in the \code{initial} part of 
the colData. 

Each bead channel should classify into two fairly clear groups where one
is the beads and the other is non-beads. A histogram of the bead score
should show a clear, small peak that represents the beads.
}
\examples{
data("raw_data", package = "CATALYST")
sce <- readCytof(raw_data, beads = 'Beads', viability = c('cisPt1','cisPt2'))
sce <- initialBead(sce)
head(scores(sce))
head(initial(sce))

}
