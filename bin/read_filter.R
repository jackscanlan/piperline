#!/usr/bin/env Rscript

# check variables defined


### run R code

# # using piperline function
# step_filter_reads(
#     sample_id = ,
#     input_dir = ,
#     output_dir = ,
#     min_length = ,
#     max_length = ,


# )

# using dada2::filterAndTrim directly
dada2::filterAndTrim(
    fwd = fwd_reads, 
    filt = paste0(sample_id,"_",target_gene,"_",pcr_primers,"_filter_R1.fastq.gz"),
    rev = rev_reads, 
    filt.rev = paste0(sample_id,"_",target_gene,"_",pcr_primers,"_filter_R2.fastq.gz"),
    minLen = as.numeric(read_min_length), 
    maxLen = as.numeric(read_max_length), 
    maxEE = as.numeric(read_max_ee), 
    truncLen = as.numeric(read_trunc_length),
    trimLeft = as.numeric(read_trim_left), 
    trimRight = as.numeric(read_trim_right), 
    rm.phix = TRUE, 
    multithread = FALSE, 
    compress = TRUE, 
    verbose = FALSE
)