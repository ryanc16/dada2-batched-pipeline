require("proto")
require("dada2")
require("hash")
source("src/File.R")
source("src/Project.R")
source("src/Batcher.R")
source("src/Logger.R")
source("src/timedtask.R")

logger<-Logger()
logger$setLogLevel(Logger.loglevel$trace)

#### Set the variables here to values for your project ####
projDir<-path.expand("~/Projects/R/sequence-data/")
dataDir<-path.expand("~/Projects/R/sequence-data/data/")
dataPattern<-"\\.fastq$"
batchSize<-4
trainingFile<-File(paste0(projDir, "silva_nr99_v138.1_train_set.fa.gz"))

Main<-function() {
  logger$info("Starting...")
  
  project<<-Project(dataDir, dataPattern)
  numsamples<-length(project$samples)
  if (numsamples == 0) {
    logger$warn("No samples in project, nothing to do, exiting!")
    return()
  }
  batcher<-Batcher(numsamples, batchSize)
  
  logger$info("Starting processing in batches of up to ", batcher$batchCount, " samples")
  message("")
  
  logger$info("===== Starting phase 1/4 =====")
  for(i in 1:batcher$getTotalIterations()) {
    batch<-batcher$getNext()
    logger$info("Starting batch ", i, "/", batcher$getTotalIterations(), ", samples ", batch$start, "-", batch$end, " of ", numsamples)
    project$setBatchRange(batch$start, batch$end)
    project$processFilterFiles()
    project$processDereps()
    logger$info("Finished batch ", i, "/", batcher$getTotalIterations())
  }
  logger$info("===== Finished phase 1/4 =====\n")
  
  logger$info("===== Starting phase 2/4 =====")
  project$setBatchRange(1, numsamples)
  project$processErrorRates()
  logger$info("===== Finished phase 2/4 =====\n")
  
  logger$info("===== Starting phase 3/4 =====")
  batcher$reset()
  for(i in 1:batcher$getTotalIterations()) {
    batch<-batcher$getNext()
    logger$info("Starting batch ", i, "/", batcher$getTotalIterations(), ", samples ", batch$start, "-", batch$end, " of ", numsamples)
    project$setBatchRange(batch$start, batch$end)
    
    project$processDada()
    project$processMerges()
    
    logger$info("Finished batch ", i, "/", batcher$getTotalIterations())
  }
  logger$info("===== Finished phase 3/4 =====\n")
  
  logger$info("===== Starting phase 4/4 =====")
  project$setBatchRange(1, numsamples)
  project$processSequenceTables()
  project$processTaxonomy(trainingFile)
  project$processTrackedReads()
  logger$info("===== Finished phase 4/4 =====\n")
  
  logger$info("Done")
  
}
timedtask(Main)