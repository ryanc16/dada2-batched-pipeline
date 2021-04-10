require("proto")

Utils<-proto(
  normalizePath=function(this, path) {
    return(gsub("/{2,}", "/", path))
  },
  dedupUnderscores=function(this, str) {
    return(gsub("_{2,}", "_", str))
  }
)