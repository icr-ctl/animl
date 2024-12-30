# animl v1.0.0

Animl comprises a variety of machine learning tools for analyzing ecological data. The package includes a set of functions to classify subjects within camera trap field data and can handle both images and videos. 

## Table of Contents
1. [Camera Trap Classificaton](#camera-trap-classification)
2. [Models](#models)
3. [Installation](#installation)

## Camera Trap Classification

Below are the steps required for automatic identification of animals within camera trap images or videos. 

#### 1. File Manifest

First, build the file manifest of a given directory.

```R
library(animl)

imagedir <- "examples/TestData"

#create save-file placeholders and working directories
WorkingDirectory(imagedir,globalenv())

# Read exif data for all images within base directory
files <- build_file_manifest(imagedir, out_file=filemanifest, exif=TRUE)

# Process videos, extract frames for ID
allframes <- extract_frames(files, out_dir = vidfdir, out_file=imageframes,
                           frames=2, parallel=T, workers=parallel::detectCores())
```
#### 2. Object Detection

This produces a dataframe of images, including frames taken from any videos to be fed into the classifier. The authors recommend a two-step approach using Microsoft's 'MegaDector' object detector to first identify potential animals and then using a second classification model trained on the species of interest. 

A version of MegaDetector compatible with tensorflow can obtained from [our server](https://sandiegozoo.box.com/s/jodg7xxxworgd85jgk4hn28z3dqlohsd).

More info on [MegaDetector](https://github.com/agentmorris/MegaDetector/tree/main).
```R
#Load the Megadetector model
md_py <- megadetector("/mnt/machinelearning/megaDetector/md_v5a.0.0.pt")

# Obtain crop information for each image
mdraw <- detect_MD_batch(md_py, allframes)

# Add crop information to dataframe
mdresults <- parse_MD(mdraw, manifest = allframes, out_file = detections)

```
#### 3. Classification
Then feed the crops into the classifier. We recommend only classifying crops identified by MD as animals.

```R
# Pull out animal crops
animals <- get_animals(mdresults)

# Set of crops with MD human, vehicle and empty MD predictions. 
empty <- get_empty(mdresults)

model_file <- "/Models/Southwest/v3/southwest_v3.pt"
class_list <- "/Models/Southwest/v3/southwest_v3_classes.csv"

# load the model
southwest <- load_model(model_file, class_list, device="cuda")

# obtain species predictions
animals <- predict_species(animals, southwest[[1]], southwest[[2]], device=device, raw=FALSE)

# recombine animal detections with remaining detections
manifest <- rbind(animals,empty)

```

# Models

The Conservation Technology Lab has several models available for use. 

* Southwest United States [v3](https://sandiegozoo.box.com/s/0mait8k3san3jvet8251mpz8svqyjnc3)
* [Amazon](https://sandiegozoo.box.com/s/dfc3ozdslku1ekahvz635kjloaaeopfl)
* [Savannah](https://sandiegozoo.box.com/s/ai6yu45jgvc0to41xzd26moqh8amb4vw)
* [Andes](https://sandiegozoo.box.com/s/kvg89qh5xcg1m9hqbbvftw1zd05uwm07)
* [MegaDetector](https://github.com/agentmorris/MegaDetector/releases/download/v5.0/md_v5a.0.0.pt)


## Installation

#### Requirements
* R >= 4.0
* Reticulate
* Python >= 3.9
* [Animl-Py = 1.4.0](https://github.com/conservationtechlab/animl-py)

We recommend running animl on a computer with a dedicated GPU.

#### Python
animl depends on python and will install python package dependencies if they are not available if installed via CRAN. <br> 
However, we recommend setting up a conda environment using the provided config file. 

[Instructions to install conda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html)

The file **animl-env.yml** describes the python version and various dependencies with specific version numbers. 
To create the enviroment, from within the animl directory run the following line in a terminal:
```
conda env create -f animl-env.yml
```
The first line creates the enviroment from the specifications file which only needs to be done once. 
This environment is also necessary for the [python version of animl.](https://pypi.org/project/animl/) 



### Contributors

Kyra Swanson <br>
Mathias Tobler <br> 
Edgar Navarro <br>
Josh Kessler <br>
Jon Kohler <br>
