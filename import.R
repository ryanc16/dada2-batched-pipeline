require('hash')

import<-function(script) {
  path<-paste0(getwd(), "/", gsub(".R", "", script), ".R")
  if(has.key(path, import.cache) == FALSE) {
    factory<-function(...) {
      inst<-source(path)$value
      if(exists("constructor", inst)) {
        inst$constructor(...)
      }
      return(inst)
    }
    import.cache[[path]]<-factory
  }
  return(import.cache[[path]])
}
import.cache<-hash()
