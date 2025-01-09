# animl Classification Workflow
#
# c 2021 Mathias Tobler
# Maintained by Kyra Swanson
#
#
#-------------------------------------------------------------------------------
# Setup
#-------------------------------------------------------------------------------
library(animl)
library(reticulate)
use_condaenv("test")

device <- 'cuda:0'

imagedir <- "/home/kyra/animl-py/examples/Southwest"

#create global variable file and directory names
WorkingDirectory(imagedir,globalenv())

# Build file manifest for all images and videos within base directory
files <- build_file_manifest(imagedir, out_file=filemanifest, exif=TRUE)

#===============================================================================
# Add Project-Specific Info
#===============================================================================

#build new name
basedepth=length(strsplit(imagedir,split="/")[[1]])
files$Region<-sapply(files$Directory,function(x)strsplit(x,"/")[[1]][basedepth])

# Process videos, extract frames for ID
allframes <- extract_frames(files, out_dir = vidfdir, out_file=imageframes,
                           frames=2, parallel=T, workers=parallel::detectCores())

#===============================================================================
# MegaDetector
#===============================================================================
# Most functions assume MegaDetector version 5. If using an earlier version of 
# MD, specify detectObjectBatch with argument 'mdversion'.

# PyTorch Via Animl-Py
md_py <- megadetector("/mnt/machinelearning/megaDetector/md_v5a.0.0.pt")

mdraw <- detect_MD_batch(md_py, allframes)
mdresults <- parse_MD(mdraw, manifest = allframes, out_file = detections)

#select animal crops for classification
animals <- get_animals(mdresults)
empty <- get_empty(mdresults)

#===============================================================================
# Species Classifier
#===============================================================================

southwest <- load_model('/mnt/machinelearning/Models/Southwest/v3/southwest_v3.pt',
                       '/mnt/machinelearning/Models/Southwest/v3/southwest_v3_classes.csv', device=device)


animals <- predict_species(animals, southwest[[1]], southwest[[2]], device=device, raw=FALSE)

manifest <- rbind(animals,empty)

# Sequence Classification



#===============================================================================
# Symlinks
#===============================================================================

#symlink species predictions
alldata <- sort_species(animals, linkdir)

#symlink MD detections only
sort_MD(manifest, linkdir)


#===============================================================================
# Export to Camera Base
#===============================================================================






