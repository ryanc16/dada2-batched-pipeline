require("proto")

proto(
  .private=proto(
    installPackages=function(this, packageList) {
      for(package in packageList) {
        require(package, character.only=TRUE)
      }
    },
    usePackages=function(this, packageList) {
      for(package in packageList) {
        library(package, character.only=TRUE)
      }
    },
    setupPackages=function(this, packageList) {
      this$installPackages(packageList)
      this$usePackages(packageList)
    }
  ),
  wd="",
  packages=c(),
  props=list(),
  constructor=function(this, wd, packages) {
    # set working directory
    this$wd<-wd
    this$packages<-packages
    setwd(wd)
    # set up packages
    this$.private$setupPackages(packages)
  },
  setProp=function(this, key, value, global=FALSE) {
    if (global==TRUE) {
      assign(key, value, envir=globalenv())
    } else {
      this$props[[key]]<-value
    }
  },
  getProp=function(this, key) {
    return(this$props[[key]])
  }
)