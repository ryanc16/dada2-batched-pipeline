timedtask<-function(task) {
  startTime<-proc.time()
  result<-task()
  message("")
  print(proc.time() - startTime)
  return(result)
}