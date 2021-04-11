source("src/Utils.R")

File<-function(filepath) {
  return(
    proto(
      path=Utils$normalizePath(path.expand(filepath)),
      exists=function(this) {
        return(file.exists(this$path))
      },
      createRecursive=function(this) {
        dir.create(dirname(this$path), recursive=TRUE, showWarnings=FALSE)
      }
    )
  )
}