# DADA2 Batched Pipeline

## Summary
This project creates a dada2 pipeline with batch processing capabilities.

## About this project
The batched processing design is particularly helpful when working with a large amount of data, either in number of samples or disk storage space, when data might exceed the available resources on the machine performing the processing.  
One goal of this project was to keep the memory storage footprint to a minimum, or at least mitigate it as best as possible to work within the means of the available resources. For example, data that is no longer needed is removed from the R environment.

Another goal was to reduce the amount of redundant work that would need to be performed within the pipeline, as some steps can take a lot of time to complete. Therefore each step of the pipeline saves the results to disk as a safety measure to fall back on. Should the processing machine power off, the script encouter an error, or the R session crash, running the script again will not need to reprocess anything that has already been processed and saved previously, and it will pick back up approximately where it left off.