#' Create SymLink Directories and Sort Classified Images
#'
#' @param manifest DataFrame of classified images 
#' @param link_dir Destination directory for symlinks
#' @param file_col 
#' @param unique_name
#' @param copy Toggle to determine copy or hard link, defaults to link
#'
#' @return manifest with added link columns
#' @export 
#'
#' @examples
#' \dontrun{
#' manifest <- sort_species(manifest, link_dir)
#' }
sort_species <- function(manifest, link_dir, file_col="FilePath", unique_name='UniqueName', copy=FALSE) {
  
  # create species directories
  for (s in unique(manifest[unique_name])) {
    dir.create(paste0(link_dir, s), recursive = TRUE,  showWarnings = FALSE)
  }
  
  if (!unique_name %in% names(manifest)) {
    manifest[unique_name] <- sapply( manifest[file_col], 
                                     function(x) paste0(strsplit(basename(x), ".", fixed = T)[[1]][1],
                                                        "_", sprintf("%05d", round(stats::runif(1, 1, 99999), 0)),
                                                        tools::file_ext(x)))
    }
  
  manifest$Link <- paste0(link_dir, manifest$prediction, "/", manifest[unique_name])
  
  # hard copy or link
  if (copy) { mapply(file.copy, manifest$FilePath, manifest$Link, MoreArgs = list(copy.date=TRUE))}
  else { mapply(file.link, manifest$FilePath, manifest$Link) }
  
  manifest
}


#' Create SymLink Directories and Sort Classified Images Based on MD Results
#'
#' @param manifest DataFrame of classified images 
#' @param link_dir Destination directory for symlinks
#' @param copy Toggle to determine copy or hard link, defaults to link
#' @param file_col 
#' @param unique_name 
#'
#' @return manifest with added link columns
#' @export
#'
#' @examples
#' \dontrun{
#' sort_MD(manifest, link_dir)
#' }
sort_MD <- function(manifest, link_dir, file_col="file", unique_name='UniqueName', copy=FALSE){

  # create directories
  MDclasses <- c("empty", "animal", "human", "vehicle")
  for (s in MDclasses) {
    dir.create(paste0(link_dir, s), recursive = TRUE,  showWarnings = FALSE)
  }
  
  manifest$MD_prediction <- sapply(manifest$category, function(x) MDclasses[x+1])
  
  if (!unique_name %in% names(manifest)) {
    manifest[unique_name] <-sapply(manifest[file_col],
                                   function(x) paste0(strsplit(basename(x), ".", fixed = T)[[1]][1],
                                                      "_", sprintf("%05d", round(stats::runif(1, 1, 99999), 0)),
                                                      tools::file_ext(x)))
  }
  
  manifest$MDLink <- paste0(link_dir, manifest$MD_prediction, "/", manifest[unique_name])

  # hard copy or link
  if (copy) { mapply(file.copy, manifest$FilePath, manifest$Link, MoreArgs = list(copy.date=TRUE))}
  else { mapply(file.link, manifest$FilePath, manifest$Link) }
  
  manifest
}


#' Remove Sorted Links
#'
#' @param link_col 
#' @param manifest DataFrame of classified images 
#'
#' @return manifest without link column
#' @export
#'
#' @examples
#' \dontrun{
#' remove_link(manifest)
#' }
remove_link <- function(manifest, link_col='Link'){
  pbapply::pbapply(manifest[link_col], file.remove)
  manifest <- manifest[, !names(manifest) %in% c(link_col)]
  manifest
}


#' Udate Results from File Browser
#'
#' @param resultsfile final results file with predictions, expects a "UniqueName" column
#' @param linkdir symlink directory that has been validated
#'
#' @return dataframe with new "Species" column that contains the verified species
#' @export
#'
#' @examples
#' \dontrun{
#' results <- updateResults(resultsfile, linkdir)
#' }
update_labels <- function(manifest, link_dir, unique_name='UniqueName'){
  if (!dir.exists(link_dir)) {stop("The given directory does not exist.")}
  if (!unique_name %in% names(manifest)) {stop("Manifest does not have unique names, cannot match to sorted directories.")}
  
  FilePath <- list.files(link_dir, recursive = TRUE, include.dirs = TRUE)
  files <- data.frame(FilePath)
  
  files[unique_name] <- sapply(files$FilePath,function(x)strsplit(x,"/")[[1]][2])
  files$label <- sapply(files$FilePath,function(x)strsplit(x,"/")[[1]][1])
  
  corrected <- merge(results, files, by=unique_name)
  return(corrected)
}
