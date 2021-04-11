require("proto")
source("src/File.R")
source("src/RDSFile.R")
source("src/FormattedString.R")
source("src/Utils.R")

Sample<-function(fwdSrc, revSrc) {

  samplename<-strsplit(basename(fwdSrc), ".", fixed = TRUE)[[1]][1]
  samplename<-gsub("_R\\d(_\\d+)?", "", samplename)
  fileFormat<-FormattedString(paste0(dirname(fwdSrc), "/{directory}/", samplename, "_{direction}_{type}.{ext}"))
  createFilePath<-function(patterns, replacements) {
    filePath<-fileFormat$replace(patterns, replacements)
    filePath<-Utils$dedupUnderscores(filePath)
    return(filePath)
  }
  
  fwdRead<-File(fwdSrc)
  fwdFilt<-File(createFilePath(c("{directory}", "{direction}", "{type}", "{ext}"), c("filtered/", "F", "filt", "fastq.gz")))
  fwdDerep<-RDSFile(createFilePath(c("{directory}", "{direction}", "{type}", "{ext}"), c("rdata/derep/", "F", "derep", "rds")))
  fwdDada<-RDSFile(createFilePath(c("{directory}", "{direction}", "{type}", "{ext}"), c("rdata/dada/", "F", "dada", "rds")))
  
  revRead<-File(revSrc)
  revFilt<-File(createFilePath(c("{directory}", "{direction}", "{type}", "{ext}"), c("filtered/", "R", "filt", "fastq.gz")))
  revDerep<-RDSFile(createFilePath(c("{directory}", "{direction}", "{type}", "{ext}"), c("rdata/derep/", "R", "derep", "rds")))
  revDada<-RDSFile(createFilePath(c("{directory}", "{direction}", "{type}", "{ext}"), c("rdata/dada/", "R", "dada", "rds")))
  
  merged<-RDSFile(createFilePath(c("{directory}", "{direction}", "{type}", "{ext}"), c("rdata/merged/", "", "merged", "rds")))
  seqtab<-RDSFile(createFilePath(c("{directory}", "{direction}", "{type}", "{ext}"), c("rdata/seqtab/", "", "seqtab", "rds")))
  seqtabNoChim<-RDSFile(createFilePath(c("{directory}", "{direction}", "{type}", "{ext}"), c("rdata/seqtab/nochim/", "", "seqtab_nochim", "rds")))
  
  return(
    proto(
      name=samplename,
      forward=proto(
        read=fwdRead,
        filt=fwdFilt,
        derep=fwdDerep,
        dada=fwdDada
      ),
      reverse=proto(
        read=revRead,
        filt=revFilt,
        derep=revDerep,
        dada=revDada
      ),
      merged=merged,
      seqtab=seqtab,
      seqtabNoChim=seqtabNoChim
    )
  )
}
