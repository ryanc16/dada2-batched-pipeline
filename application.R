require("proto")
source("mock-dada.R")
source("import.R")
local_env<-import("env")
local_project<-import("project")

packages<-c()
env<-local_env("~/R/sequence-data/", packages)
env$setProp("multithread", TRUE, global=TRUE)

application<-proto(
  
  project=proto(),
  
  main=function(this, ...args) {
    this$project<-local_project()
  }
  
)
application$main()
