require("proto")

Logger<-function() {
  return(
    proto(
      .private=proto(
        formatLog=function(this, level, ...) {
          return(paste0("[", level, "]\t", Sys.time(), "\t", ...))
        },
        getLogLevelInt=function(this) {
          return(Logger.loglevel[[Logger.loglevel[[this$logLevel]]]])
        },
        logLevel="info"
      ),
      debug=function(this, ...) {
        if (this$.private$getLogLevelInt() <= Logger.loglevel$debug) {
          message(this$.private$formatLog("debug", ...))
        }
      },
      trace=function(this, ...) {
        if (this$.private$getLogLevelInt() <= Logger.loglevel$trace) {
          message(this$.private$formatLog("trace", ...))
        }
      },
      info=function(this, ...) {
        if (this$.private$getLogLevelInt() <= Logger.loglevel$info) {
          message(this$.private$formatLog("info", ...))
        }
      },
      warn=function(this, ...) {
        if (this$.private$getLogLevelInt() <= Logger.loglevel$warn) {
          message(this$.private$formatLog("warn", ...))
        }
      },
      error=function(this, ...) {
        if (this$.private$getLogLevelInt() <= Logger.loglevel$error) {
          message(this$.private$formatLog("error", ...))
        }
      },
      setLogLevel=function(this, level) {
        this$.private$logLevel<-level
      }
    )
  )
}
Logger.loglevel<-list(
  "debug"=1,
  "trace"=2,
  "info"=3,
  "warn"=4,
  "error"=5
)