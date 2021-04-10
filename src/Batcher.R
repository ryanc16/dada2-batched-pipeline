require("proto")

Batcher<-function(totalCount, batchCount) {
  return(
    proto(
      totalCount=totalCount,
      batchCount=batchCount,
      counter=0,
      getTotalIterations=function(this) {
        return(
          ceiling(this$totalCount/this$batchCount)
        )
      },
      getNext=function(this) {
        startIdx<-this$counter+1
        this$counter<-min(this$counter+this$batchCount, this$totalCount)
        endIdx<-this$counter
        return(
          list(
            start=startIdx,
            end=endIdx
          )
        )
      },
      reset=function(this) {
        this$counter<-0
      }
    )
  )
}