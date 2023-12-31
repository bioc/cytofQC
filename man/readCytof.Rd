% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/readCytof.R
\name{readCytof}
\alias{readCytof}
\title{Read in a dataset and prepare it for analysis}
\usage{
readCytof(
  file.name,
  beads = c("Bead"),
  dna = c("DNA1", "DNA2"),
  event_length = "Event_length",
  viability = "Live_Dead",
  gaussian = c("Center", "Offset", "Width", "Residual"),
  verbose = TRUE
)
}
\arguments{
\item{file.name}{A path to an .fcs file that contains CyTOF data or a 
\code{flowSet} object containing a single sample.}

\item{beads}{character vector that contains the names of all of the bead 
channels.}

\item{dna}{Character vector that contains the names of the DNA markers.}

\item{event_length}{Character vector of the event length variable.}

\item{viability}{Character vector of the permeability/viability markers.}

\item{gaussian}{Character vector that contains the names of the Gaussian 
Discrimination Parameters.}

\item{verbose}{Logical value indicating whether or not to print a summary of
the technical channels identified in the data.}
}
\value{
A \code{SingleCellExperiment} that contains the information from
the CyTOF fcs file, the technical data that will be used to label 
the data, and other objects that are used to store information through
the labeling process. The objects are \code{DataFrame} objects that
are stored in the \code{colData} for the \code{SingleCellExperiment}. 
The objects are: 
\item{label}{A single variable \code{DataFrame} that will contain the
event label as determined by \code{cytofQC}. At this point, all events
are labeled "gdpZero" if \code{Event_length} or any of the Gaussian
parameters are zero and "cell" otherwise. These labels are changed during
later stages.}
\item{probs}{A \code{DataFrame} that contains the "probability" that an
event is a certain type. This is initialized as NA at 
this point and is filled in later on.}
\item{tech}{A \code{DataFrame} that contains the technical variables
used to determine the label of each event. The bead, DNA, and viability
variables have an arcsinh transform, Event_length is unchanged, and 
the Gaussian parameters have a log transform using \code{log1p}.}
\item{scores}{Scores are computed to determine how much an event looks
like a bead, debris, doublet, or dead cell. These scores are used 
to select a training dataset for the classification model, but they 
can be helpful for exploratory data analysis so they are provided in 
this \code{DataFrame}. At this stage they are initialized as NA and
values are added in later steps.}
\item{initial}{Initial classification of each event type is determined
using a mixture model and the event type score. The \code{initial}
object is a \code{DataFrame} that will hold this initial classification.
A training dataset for the event classification model is selected using 
this initial classification.}
}
\description{
Read in a dataset and prepare it for analysis
}
\details{
The function returns a \code{SingleCellExperiment} that contains all of 
the original information from the fcs file. The data are imported using
\code{CATALYST} and then information is added to the \code{colData}
that will be used to determine labels for each event and to provide
additional information about the events that can be used for 
exploratory data analysis and to aid the user in labeling the data. 
The objects are all initialized at this point an values are filled 
in during later stages of the labeling process.
Note that the names from the fcs file are required as arguments 
to the \code{readCytof}. If you are not sure what those names are, 
there is some code in the example that shows how to import your 
data into a \code{SingleCellExperiment} using \code{prepData} from
\code{CATALYST} and look at the names.
}
\examples{
library(CATALYST)
library(SingleCellExperiment)
data("raw_data", package = "CATALYST")

# Determine at the names of the bead, DNA, and viability channels in the 
# file. Names are 'Beads', 'DNA1', 'DNA2', 'cisPt1', 'cisPt2'.
tech <- prepData(raw_data)
rownames(tech) 

# Determine names of event length and Gaussian parameters
# names are 'Event_length', 'Center', 'Offset', 'Width', 'Residual'
names(int_colData(tech)) 

# read in the data for use with cytofQC
x <- readCytof(raw_data, beads = 'Beads', viability = c('cisPt1','cisPt2'))

}
