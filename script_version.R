derepFastq<-function(file) {
  return("derep result")
}

dada<-function(derepresult, errF, multithread) {
  return("dada result")
}

learnErrors<-function(fastqfiles, multithread) {
  return("learnErrors result")
}

#######################################################

dereps<-function(fastqfile, learnedError, samplename, direction) {
  print(paste("Processing:", fastqfile))
  filename<-paste0(samplename,"-",direction,"-derep.RDS")
  startTime<-proc.time()
  # dereplicate the fastqfile
  derep<-derepFastq(samplename)
  # dada the file and use the derep
  dds<-dada(derep,err=learnedError,multithread=TRUE)
  Sys.sleep(3)
  duration<-proc.time() - startTime
  print(duration)
  print(paste("Writing file:", filename))
  # write out file
  return(dds)
}

#######################################################

filtFs<-c(
  "~/scratch/CD1-1-F.fastq",
  "~/scratch/CD1-2-F.fastq"
)
filtRs<-c(
  "~/scratch/CD1-1-R.fastq",
  "~/scratch/CD1-2-R.fastq"
)

forward.sample.names<-c(
  "CD1-1",
  "CD1-2"
)
reverse.sample.names<-c(
  "CD1-1",
  "CD1-2"
)

errF<-learnErrors(filtFs, multithread=TRUE)
errR<-learnErrors(filtRs, multithread=TRUE)

ddsF<-vector("list", length(forward.sample.names))
names(ddsF)<-forward.sample.names

for(i in 1:length(filtFs)) {
  samplename<-forward.sample.names[i]
  ddsF[[samplename]]<-dereps(filtFs[i], errF, samplename, "F")
}
