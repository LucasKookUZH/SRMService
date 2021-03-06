# Run script for WebGestaltR ORA analysis of MQ two group comparison on protein level

rm(list = ls())
library(limma)
library(SRMService)
library(WebGestaltR)
library(tidyverse)
library(quantable)
source("R/WebGestaltWrappR.R")

### Protein groups file
packagedir <- path.package("SRMService")

file = "pullDown"

if(file == "yeast") {
  proteinGroupsFile <-
    file.path(packagedir, "samples/proteinGroups/proteinGroupsYeast.txt")
  organism <- "scerevisiae"
  Experimentname <- "yeast_example"
  indx <- 4
} else if(file == "mouse") {
  proteinGroupsFile <-
    file.path(packagedir, "samples/proteinGroups/proteinGroups.txt")
  organism <- "mmusculus"
  Experimentname <- "mouse_example"
  indx <- 3
} else if(file == "pullDown") {
  proteinGroupsFile <-
    file.path(packagedir, "samples/proteinGroups/proteinGroupsPullDown.txt")
  organism <- "hsapiens"
  Experimentname <- "pullDown_example"
  indx <- 4
}

protein <- readr::read_tsv(proteinGroupsFile)
colnames(protein) <- make.names(colnames(protein))

rawF <- gsub("Intensity\\.", "", grep("Intensity\\.", colnames(protein), value = TRUE))
condition <- quantable::split2table(rawF)[, indx]

annotation <- data.frame(
  Raw.file = rawF,
  Condition = condition,
  BioReplicate = paste0("X", 1:length(condition)),
  Run = 1:length(condition),
  IsotopeLabelType = rep("L", length(condition)),
  stringsAsFactors = FALSE
)

###################################
### Configuration section

resultdir <- "output"
dir.create(resultdir)
dir.create("output/ORA_inputFiles/")

nrNas = 5
nrPeptides = 2
reference = unique(annotation$Condition)[1]
qvalueThreshold = 0.05
qfoldchange = 1
numberOfProteinClusters = 2
enrichDatabase = "pathway_KEGG"
write.table(annotation, file = file.path(resultdir, "annotationused.txt"))


####### END of user configuration ##

# source("R/Grp2Analysis.R")
grp2 <- Grp2Analysis(
  annotation,
  Experimentname,
  maxNA = nrNas,
  nrPeptides = nrPeptides,
  reference = reference,
  numberOfProteinClusters = numberOfProteinClusters
)

grp2$setMQProteinGroups(protein)
grp2$setQValueThresholds(qvalue = qvalueThreshold, qfoldchange = qfoldchange)
mqQuantMatrixGRP2 <- grp2

webGestaltExample <-
  webGestaltWrapper(
    grp2 = grp2,
    enrichDatabase = enrichDatabase,
    organism = organism,
    se_threshold = 1.5,
    nrNas = 5,
    method = "complete"
  )

usethis::use_data(webGestaltExample, overwrite = TRUE)

#REMOVE to render
rmarkdown::render(
  "vignettes/WebGestaltR_Grp2Analysis.Rmd",
  bookdown::html_document2(number_sections = FALSE),
  params = list(config = webGestaltExample),
  clean = TRUE
)
