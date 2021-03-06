source("src/DataFile.R")

CSVFile<-function(filepath) {
  return(
    as.proto(
      parent=DataFile(filepath),
      x=list(
        .load=function(this) {
          return(read.csv(this$path))
        },
        .save=function(this, data) {
          write.csv(data, this$path)
        }
      )
    )
  )
}