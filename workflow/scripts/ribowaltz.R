library(riboWaltz)

reads_list <- bamtolist(bamfolder = "path/to/BAM/files", annotation = annotation_dt, transcript_align = FALSE)

# Filter by read lengths satisfying periodicity threshold
 filtered_list <- length_filter(data = example_reads_list,
 				length_filter_mode = "periodicity",
 				periodicity_threshold = 70)