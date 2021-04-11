require("proto")
source("src/RDSFile.R")
source("src/CSVFile.R")
source("src/Sample.R")
source("src/Logger.R")

logger<-Logger()
logger$setLogLevel(Logger.loglevel$trace)

Project<-function(dataDir, dataPattern) {
  
  logger$info("Creaing project for: ", dataDir)
  
  logger$info("Reading samples on disk")
  fileQueryPath<-dataDir
  fileQueryPattern<-dataPattern
  
  logger$debug("listing files from disk in path: ", fileQueryPath, " using pattern: ", fileQueryPattern)
  filesondisk<-list.files(fileQueryPath, pattern=fileQueryPattern, full.names=TRUE)
  logger$info(length(filesondisk), " samples found on disk")
  samples<-list()
  
  if (length(filesondisk) > 0) {
    numFiles<-length(filesondisk)
    multiplier<-2
    itr<-(numFiles/2)-1
    for(i in 0:itr) {
      fwd<-filesondisk[[i*multiplier+1]]
      rev<-filesondisk[[i*multiplier+2]]
      sample<-Sample(fwd, rev)
      samples<-append(samples, list(sample))
    }
    logger$info(length(samples), " samples prepared in total")
    
  } else {
    logger$warn("No samples were found. Check the provided datadir path?")
  }
  logger$info("Finished creating project")
  return(
    proto(
      fwdError=RDSFile(paste0(dataDir, "rdata/err_F.rds")),
      revError=RDSFile(paste0(dataDir, "rdata/err_R.rds")),
      seqtab=RDSFile(paste0(dataDir, "rdata/seqtab/seqtab.rds")),
      seqtabNoChim=RDSFile(paste0(dataDir, "rdata/seqtab/nochim/seqtab_nochim.rds")),
      seqtabNoChimCsv=CSVFile(paste0(dataDir, "results/seqtab_nochim.csv")),
      taxonomy=RDSFile(paste0(dataDir, "rdata/taxonomy.rds")),
      taxonomyCsv=CSVFile(paste0(dataDir, "results/taxonomy.csv")),
      tracked=RDSFile(paste0(dataDir, "rdata/tracked.rds")),
      trackedCsv=CSVFile(paste0(dataDir, "results/tracked.csv")),
      samples=samples,
      batchRange=seq(0,0),
      setBatchRange=function(this, start, end) {
        this$batchRange=seq(start, end)
      },
      getSampleSubset=function(this, start, end) {
        return(this$samples[start:end])
      },
      getBatch=function(this) {
        return(this$samples[this$batchRange])
      },
      getAllSampleNames=function(this) {
        return(unlist(lapply(this$samples, function(sample) sample$name)))
      },
      getSampleNames=function(this) {
        samples<-this$getBatch()
        return(unlist(lapply(samples, function(sample) sample$name)))
      },
      getReads=function(this) {
        samples<-this$getBatch()
        readsF<-lapply(samples, function(sample) sample$forward$read)
        readsR<-lapply(samples, function(sample) sample$reverse$read)
        return(
          list(
            forward=readsF,
            reverse=readsR
          )
        )
      },
      getFilteredReads=function(this) {
        samples<-this$getBatch()
        filtsF<-lapply(samples, function(sample) sample$forward$filt)
        filtsR<-lapply(samples, function(sample) sample$reverse$filt)
        return(
          list(
            forward=filtsF,
            reverse=filtsR
          )
        )
      },
      getDereplicatedReads=function(this) {
        samples<-this$getBatch()
        derepsF<-lapply(samples, function(sample) sample$forward$derep)
        derepsR<-lapply(samples, function(sample) sample$reverse$derep)
        return(
          list(
            forward=derepsF,
            reverse=derepsR
          )
        )
      },
      getDadas=function(this) {
        samples<-this$getBatch()
        dadasF<-lapply(samples, function(sample) sample$forward$dada)
        dadasR<-lapply(samples, function(sample) sample$reverse$dada)
        return(
          list(
            forward=dadasF,
            reverse=dadasR
          )
        )
      },
      getMergedPairs=function(this) {
        samples<-this$getBatch()
        return(lapply(samples, function(sample) sample$merged))
      },
      getSequenceTables=function(this) {
        samples<-this$getBatch()
        return(lapply(samples, function(sample) sample$seqtab))
      },
      getSequenceTablesNoChims=function(this) {
        samples<-this$getBatch()
        return(lapply(samples, function(sample) sample$seqtabNoChim))
      },
      getTaxonomyFiles=function(this) {
        samples<-this$getBatch()
        return(lapply(samples, function(sample) sample$taxonomy))
      },
      processFilterFiles=function(this) {
        logger$info("Filtering reads")
        
        reads<-this$getReads()
        readsF<-reads$forward
        readsR<-reads$reverse
        
        filts<-this$getFilteredReads()
        
        filtsF<-filts$forward
        filtsFMissing<-unlist(lapply(filtsF, function(file) !file$exists()))
        filtsF<-filtsF[filtsFMissing]
        readsF<-readsF[filtsFMissing]
        
        filtsR<-filts$reverse
        filtsRMissing<-unlist(lapply(filtsR, function(file) !file$exists()))
        filtsR<-filtsR[filtsRMissing]
        readsR<-readsR[filtsRMissing]
        
        logger$info(length(filtsF), " forward reads in batch need filtered")
        logger$info(length(filtsR), " reverse reads in batch need filtered")
        if (length(filtsF) > 0 || length(filtsR) > 0) {
          readsFPaths<-unlist(lapply(readsF, function(file) file$path))
          readsRPaths<-unlist(lapply(readsR, function(file) file$path))
          filtsFPaths<-unlist(lapply(filtsF, function(file) file$path))
          filtsRPaths<-unlist(lapply(filtsR, function(file) file$path))
          timedtask(function() {
            filterAndTrim(readsFPaths, filtsFPaths, readsRPaths, filtsRPaths,
                          truncLen=c(240, 160), maxN=0, maxEE=c(2,2),
                          rm.phix=TRUE, compress=TRUE,
                          multithread=TRUE, verbose=2)
          })
        }
      },
      processDereps=function(this) {
        logger$info("Dereplicating filtered reads")
        
        dereps<-this$getDereplicatedReads()
        filts<-this$getFilteredReads()
        
        derepsF<-dereps$forward
        derepsFMissing<-unlist(lapply(derepsF, function(file) !file$exists()))
        derepsF<-derepsF[derepsFMissing]
        filtsF<-filts$forward[derepsFMissing]
        
        derepsR<-dereps$reverse
        derepsRMissing<-unlist(lapply(derepsR, function(file) !file$exists()))
        derepsR<-derepsR[derepsRMissing]
        filtsR<-filts$reverse[derepsRMissing]
        
        logger$info(length(derepsF), " filtered forward reads in batch need dereplicated")
        logger$info(length(derepsR), " filtered reverse reads in batch need dereplicated")
        
        if (length(derepsF) > 0) {
          
          derepsResult<-timedtask(function() {
            derepFastq(unlist(lapply(filtsF, function(file) file$path)), verbose=2)
          })
          
          ## when derepFastq is provided a list of size 1, it does not return a list of size 1,
          ## it instead returns a single derep-class object
          ## Handle the case of only 1 file here by putting that 1 result in a list
          if (length(derepsF) == 1) {
            derepsResult<-list(derepsResult)
          }
          
          for (i in 1:length(derepsF)) {
            logger$trace("Saving derep result:", derepsF[[i]]$path)
            derepsF[[i]]$save(derepsResult[[i]])
          }
        }
        
        if (length(derepsR) > 0) {
          derepsResult<-timedtask(function() {
            derepFastq(unlist(lapply(filtsR, function(file) file$path)), verbose=2)
          })
          
          ## when derepFastq is provided a list of size 1, it does not return a list of size 1,
          ## it instead returns a single derep-class object
          ## Handle the case of only 1 file here by putting that 1 results in a list
          if (length(derepsR) == 1) {
            derepsResult<-list(derepsResult)
          }
          
          for (i in 1:length(derepsR)) {
            logger$trace("Saving derep result:", derepsR[[i]]$path)
            derepsR[[i]]$save(derepsResult[[i]])
          }
        }
      },
      processErrorRates=function(this) {
        logger$info("Processing error rates")
        
        if (!this$fwdError$exists()) {
          logger$info("Forward read error rate needs calculated")
          filts<-this$getFilteredReads()
          filtsF<-lapply(filts$forward, function(filt) filt$path)
         errF<-timedtask(function() {
            learnErrors(filtsF, multithread=TRUE, randomize=FALSE, verbose=1)
          })
          this$fwdError$save(errF)
        } else {
          logger$info("Forward read error rate already on disk")
        }
        
        if (!this$revError$exists()) {
          logger$info("Reverse read error rate needs calculated")
          filts<-this$getFilteredReads()
          filtsR<-lapply(filts$reverse, function(filt) filt$path)
          errR<-timedtask(function() {
            learnErrors(filtsR, multithread=TRUE, randomize=FALSE, verbose=1)
          })
          this$revError$save(errR)
        } else {
          logger$info("Reverse read error rate already on disk")
        }
      },
      processDada=function(this) {
        logger$info("Performing sample inference")
        
        dadas<-this$getDadas()
        dereps<-this$getDereplicatedReads()
        
        dadasF<-dadas$forward
        dadasFMissing<-unlist(lapply(dadasF, function(file) !file$exists()))
        dadasF<-dadasF[dadasFMissing]
        derepsF<-dereps$forward[dadasFMissing]
        
        dadasR<-dadas$reverse
        dadasRMissing<-unlist(lapply(dadasR, function(file) !file$exists()))
        dadasR<-dadasR[dadasRMissing]
        derepsR<-dereps$reverse[dadasRMissing]
        
        logger$info(length(dadasF), " forward samples in batch need inferences processed")
        logger$info(length(dadasR), " reverse samples in batch need inferences processed")
        
        if (length(dadasF) > 0) {
          logger$info("Performing sample inferences on forward reads")
          derepsFData<-lapply(derepsF, function(file) file$load())
          dadaResults<-timedtask(function() {
            dada(derepsFData, err=this$fwdError$load(), multithread=TRUE, verbose=1)
          })
          
          if (length(dadasF) == 1) {
            dadaResults<-list(dadaResults)
          }
          
          for (i in 1:length(dadasF)) {
            logger$trace("Saving dada result: ", dadasF[[i]]$path)
            dadasF[[i]]$save(dadaResults[[i]])
          }

          lapply(derepsF, function(file) file$unload())
          this$fwdError$unload()
        }
        
        if (length(dadasR) > 0) {
          logger$info("Performing sample inferences on reverse reads")
          derepsRData<-lapply(derepsR, function(file) file$load())
          dadaResults<-timedtask(function() {
            dada(derepsRData, err=this$revError$load(), multithread=TRUE, verbose=1)
          })
          
          if (length(dadasR) == 1) {
            dadaResults<-list(dadaResults)
          }
          
          for (i in 1:length(dadasR)) {
            logger$trace("Saving dada result: ", dadasR[[i]]$path)
            dadasR[[i]]$save(dadaResults[[i]])
          }
          
          lapply(derepsR, function(file) file$unload())
          this$revError$unload()
        }
      },
      processMerges=function(this) {
        logger$info("Performing sample merging")
        
        merged<-this$getMergedPairs()
        mergesMissing<-unlist(lapply(merged, function(file) !file$exists()))
        merged<-merged[mergesMissing]
        
        logger$info(length(merged), " samples in batch need merged")
        if (length(merged) > 0) {
          dadas<-this$getDadas()
          
          dadaF<-lapply(dadas$forward[mergesMissing], function(file) file$load())
          dadaR<-lapply(dadas$reverse[mergesMissing], function(file) file$load())
          
          dereps<-this$getDereplicatedReads()
          
          derepF<-lapply(dereps$forward[mergesMissing], function(file) file$load())
          derepR<-lapply(dereps$reverse[mergesMissing], function(file) file$load())
          
          logger$trace("Merging ", paste(lapply(dadas$forward, function(file) file$path), "and", lapply(dadas$reverse, function(file) file$path), "\n"))
          
          mergedResult<-timedtask(function() {
            mergePairs(dadaF, derepF, dadaR, derepR, verbose=2)
          })
          
          if (length(merged) == 1) {
            mergedResult<-list(mergedResult)
          }
          
          for (i in 1:length(merged)) {
            merged[[i]]$save(mergedResult[[i]])
          }
          
          lapply(dadas$forward, function(file) file$unload())
          lapply(dadas$reverse, function(file) file$unload())
          lapply(dereps$forward, function(file) file$unload())
          lapply(dereps$reverse, function(file) file$unload())
        }
      },
      processSequenceTables=function(this) {
        
        logger$info("Creating sequence tables")
        
        seqtabs<-this$getSequenceTables()
        seqtabsMissing<-unlist(lapply(seqtabs, function(file) !file$exists()))
        seqtabs<-seqtabs[seqtabsMissing]
        names<-this$getSampleNames()[seqtabsMissing]
        
        logger$info(length(seqtabs), " samples need sequence tables created")
        
        if (length(seqtabs) > 0) {
          merged<-this$getMergedPairs()
          merged<-merged[seqtabsMissing]
          mergedData<-lapply(merged, function(file) file$load())

          seqtabResult<-timedtask(function() {
            makeSequenceTable(mergedData)
          })
          rownames(seqtabResult)<-names
          
          logger$info("Saving sequence table")
          this$seqtab$save(seqtabResult)
          
          ## Unload all the merged file data
          lapply(merged, function(file) file$unload())
          
          logger$info("Saving individual sequence tables")
          for (i in 1:length(merged)) {
            logger$trace("Saving sequence table ", seqtabs[[i]]$path)
            ## Separate out each row and construct it into a table with 1 row
            seqtabSubsetTable<-t(matrix(seqtabResult[i,]))
            rownames(seqtabSubsetTable)<-names[[i]]
            colnames(seqtabSubsetTable)<-colnames(seqtabResult)
            seqtabs[[i]]$save(seqtabSubsetTable)
          }
        }
        
        ## should we create the combined sequence table?
        seqtabs<-this$getSequenceTables()
        seqtabsExist<-unlist(lapply(seqtabs, function(file) file$exists()))
        if (all(seqtabsExist) && !this$seqtab$exists()) {
          logger$info("Saving sequence table")
          seqtabData<-lapply(seqtabs, function(file) file$load())
          seqtabMatrix<-do.call(rbind, seqtabData)
          this$seqtab$save(seqtabMatrix)
          lapply(seqtabs, function(file) file$unload())
        }
        
        seqtabNoChims<-this$getSequenceTablesNoChims()
        seqtabNoChimsMissing<-unlist(lapply(seqtabNoChims, function(file) !file$exists()))
        seqtabNoChims<-seqtabNoChims[seqtabNoChimsMissing]
        
        if (length(seqtabNoChims) > 0) {
          seqtabs<-this$getSequenceTables()[seqtabNoChimsMissing]
          seqtabData<-lapply(seqtabs, function(file) file$load())
          ## Reconstruct a single multirow table from the loaded tables
          combinedSeqtab<-do.call(rbind, seqtabData)
          
          logger$info("Removing bimeras")
          seqtabNoChimResult<-timedtask(function() {
            removeBimeraDenovo(combinedSeqtab, method="consensus", multithread=TRUE, verbose=2)
          })
          
          logger$info("Saving sequence table (without bimeras)")
          this$seqtabNoChim$save(seqtabNoChimResult)
          
          ## Unload all the seqtab file data
          lapply(seqtabs, function(file) file$unload())
          
          logger$info("Saving individual sequence tables (without bimeras)")
          for (i in 1:length(seqtabs)) {
            logger$trace("Saving sequence table ", seqtabNoChims[[i]]$path)
            ## Separate out each row and construct it into a table with 1 row
            seqtabNoChimSubsetTable<-t(matrix(seqtabNoChimResult[i,]))
            rownames(seqtabNoChimSubsetTable)<-names[[i]]
            colnames(seqtabNoChimSubsetTable)<-colnames(seqtabNoChimResult)
            seqtabNoChims[[i]]$save(seqtabNoChimSubsetTable)
          }
        }
        
        ## should we create the combined sequence no chim table?
        seqtabNoChims<-this$getSequenceTablesNoChims()
        seqtabNoChimsExist<-unlist(lapply(seqtabNoChims, function(file) file$exists()))
        if (all(seqtabNoChimsExist) && !this$seqtabNoChim$exists()) {
          logger$info("Saving sequence table (without bimeras)")
          seqtabNoChimData<-lapply(seqtabNoChims, function(file) file$load())
          seqtabNoChimMatrix<-do.call(rbind, seqtabNoChimData)
          this$seqtabNoChim$save(seqtabNoChimMatrix)
          lapply(seqtabs, function(file) file$unload())
        }
        
        if (this$seqtabNoChim$exists() && !this$seqtabNoChimCsv$exists()) {
          logger$info("Saving sequence table (without bimeras) csv")
          this$seqtabNoChimCsv$save(this$seqtabNoChim$load())
          this$seqtabNoChim$unload()
        }
      },
      processTaxonomy=function(this, trainingFile) {
        logger$info("Assigning taxonomy")
        if (!this$taxonomy$exists()) {
          seqtabNoChims<-this$getSequenceTablesNoChims()
          seqtabNoChimData<-lapply(seqtabNoChims, function(file) file$load())
          seqtabNoChimMatrix<-do.call(rbind, seqtabNoChimData)
          
          logger$info("Using training file: ", trainingFile$path)
          taxa<-timedtask(function() {
            assignTaxonomy(seqtabNoChimMatrix, trainingFile$path, multithread=TRUE, verbose=2)
          })
          logger$info("Saving taxonomy table")
          this$taxonomy$save(taxa)
          this$taxonomyCsv$save(taxa)
        }
      },
      processTrackedReads=function(this) {
        
        logger$info("Generating tracked reads")
        
        if (!this$tracked$exists()) {
          getN<-function(x) sum(getUniques(x))
          
          sampleNames<-this$getAllSampleNames()
          
          logger$info(length(sampleNames), " samples will have tracked reads generated")
          
          reads<-this$getReads()
          filts<-this$getFilteredReads()
          dereps<-this$getDereplicatedReads()
          dadas<-this$getDadas()
          merges<-this$getMergedPairs()
          seqtabs<-this$seqtab$load()
          seqtabNoChims<-this$seqtabNoChim$load()
          
          columns<-c("Reads F", "Reads R", "FiltsF", "FiltsR", "Dereps F", "Dereps R", "Dadas F", "Dadas R", "Merged", "SeqTab", "SeqTabNoChim")
          tracked<-matrix(nrow=length(sampleNames), ncol=length(columns), dimnames=list(sampleNames, columns), byrow=TRUE)
          for (i in 1:length(sampleNames)) {
            logger$trace("Determining tracked reads for ", sampleNames[[i]])
            readsFN<-getN(reads$forward[[i]]$path)
            readsRN<-getN(reads$reverse[[i]]$path)
            filtsFN<-getN(filts$forward[[i]]$path)
            filtsRN<-getN(filts$reverse[[i]]$path)
            derepFN<-getN(dereps$forward[[i]]$load())
            derepRN<-getN(dereps$reverse[[i]]$load())
            dadaFN<-getN(dadas$forward[[i]]$load())
            dadaRN<-getN(dadas$reverse[[i]]$load())
            mergedN<-getN(merges[[i]]$load())
            seqtabN<-sum(seqtabs[i,])
            seqtabNoChimN<-sum(seqtabNoChims[i,])
            
            tracked[i,]<-c(readsFN, readsRN, filtsFN, filtsRN, derepFN, derepRN, dadaFN, dadaRN, mergedN, seqtabN, seqtabNoChimN)
            
            dereps$forward[[i]]$unload()
            dereps$reverse[[i]]$unload()
            dadas$forward[[i]]$unload()
            dadas$reverse[[i]]$unload()
            merges[[i]]$unload()
          }
          this$seqtab$unload()
          this$seqtabNoChim$unload()
          
          logger$info("Saving tracked reads")
          this$tracked$save(tracked)
          this$trackedCsv$save(tracked)
        }
      }
    )
  )
  
}