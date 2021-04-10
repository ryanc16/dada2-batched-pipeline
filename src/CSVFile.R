source("src/File.R")

CSVFile<-function(filepath) {
  return(
    as.proto(
      parent=File(filepath),
      x=list(
        data=NULL,
        load=function(this, force=FALSE) {
          if (force==TRUE || is.null(this$data)) {
            logger$debug("loading: ", this$path)
            this$data<-read.csv(this$path)
          }
        },
        save=function(this, data) {
          logger$debug("saving: ", this$path)
          this$createRecursive()
          write.csv(data, this$path)
        },
        isLoaded=function(this) {
          return(!is.null(this$data))
        },
        unload=function(this) {
          logger$debug("unloading: ", this$path)
          rm('data', envir = this)
          this$data = NULL
        }
      )
    )
  )
}