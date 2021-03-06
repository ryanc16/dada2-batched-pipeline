require('proto')

proto(
  .private=proto(
    identifier=""
  ),
  names=vector("character"),
  files=vector("character"),
  filters=vector("character"),
  errors=NULL,
  dereps=vector("list"),
  constructor=function(this, identifier) {
    this$.private$identifier<-identifier
    this$parseFiles()
    this$learnError()
    this$dereps<-vector("list", length(this$filters))
    for(i in 1:length(this$filters)) {
      fastqfile<-this$files[i]
      samplename<-this$names[i]
      this$dereps[[samplename]]<-this$derep(fastqfile, samplename)
    }
  },
  parseFiles=function(this){
    files<-list.files(paste0(getwd(),"/fastq"),full.names=TRUE)
    this$names=vector("character", length(files))
    this$files=vector("character", length(files))
    i<-1
    for(filepath in files) {
      pathparts<-strsplit(filepath, "/", fixed=TRUE)[[1]]
      filename<-pathparts[length(pathparts)]
      samplename<-strsplit(filename, ".", fixed=TRUE)[[1]][1]
      
      this$files[i]<-filename
      this$names[i]<-samplename
      
      i<-i+1
    }
  },
  learnError=function(this) {
    this$filters<-this$files
    this$errors<-learnErrors(this$filters, multithread=multithread)
  },
  derep=function(this, fastqfile, samplename) {
    print(paste("Processing:", fastqfile))
    outfile<-paste0(env$wd, samplename, "-", this$.private$identifier, "-derep.RDS")
    startTime<-proc.time()
    # dereplicate the fastqfile
    derepped<-derepFastq(fastqfile)
    # dada the file and use the derep
    dds<-dada(derepped, err=this$errors, multithread=multithread)
    Sys.sleep(3)
    duration<-proc.time() - startTime
    print(duration)
    print(paste("Writing file:", outfile))
    # write out file
    return(dds)
  }
)