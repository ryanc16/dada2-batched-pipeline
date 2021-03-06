require("proto")
samples<-import("samples")

proto(
  .private=proto(
    
  ),
  samples=proto(
    forward=samples("F"),
    reverse=samples("R")
  ),
  constructor=function(this) {
    
  }
)