source("src/DataFile.R")

RDSFile<-function(filepath) {
  return(
    as.proto(
      parent=DataFile(filepath),
      x=list(
        .load=function(this) {
          return(readRDS(this$path))
        },
        .save=function(this, data) {
          saveRDS(data, this$path)
        }
      )
    )
  )
}