# DADA2 Batched Pipeline

## Summary
This project creates a dada2 pipeline with batch processing capabilities.

## About this project
The batched processing design is particularly helpful when working with a large amount of data, either in number of samples or disk storage space, when data might exceed the available resources on the machine performing the processing.  

### Goals
There were two main goals and motivations for this project:
1. Reduce and provide a means to mitigate the amount of required machine resources to compute large datasets.
2. Save data as its processed throughout the pipeline as a safety fallback in the event of an unexpected failure during processing.

#### Goal 1 - Reduce required machine resources
In order to keep the memory footprint to a minimum, or at least mitigate it as best as possible to work within the means of the available resources, two measures were put in place:
1. Batching the number of samples that are processed at a given time.
2. Data that is no longer needed is removed from the R environment.

#### Goal 2 - Reduce required re-processing
Some steps in the pipeline can take a long time to perform. In an effort to reduce the amount of redundant work that would need to be re-performed (and save your sanity) in the event of a devastating R session crash, two measures were put in place:
1. Each step of the pipeline saves the results to disk as a safety measure to fall back on.
2. Use the saved data when re-running the script to fill in the blanks for data that would otherwise need to be re-processed.

Should the processing machine power off, the script encouter an error, or the R session crash, running the script again will not need to reprocess anything that has already been processed and saved previously, and it will pick back up approximately where it left off.