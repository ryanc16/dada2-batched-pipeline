require("proto")

FormattedString<-function(format) {
  return(
    proto(
      .private=proto(
        format=format
      ),
      replace=function(this, patterns, replacements) {
        str<-this$.private$format
        for (i in 1:length(patterns)) {
          str<-gsub(patterns[[i]], replacements[[i]], str, fixed=TRUE)
        }
        return(str)
      }
    )
  )
}