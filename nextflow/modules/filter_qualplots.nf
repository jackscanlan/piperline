process FILTER_QUALPLOTS {
    def module_name = "filter_qualplots"
    tag "Whole pipeline" 
    // label:  

    input:
    tuple val(meta), path(reads)

    output:   
    path("*_qualplots.pdf")                 , emit: plots

    publishDir "${projectDir}/output/modules/${module_name}", mode: 'copy'

    // when: 

    script:
    def module_script = "${module_name}.R"
    """
    #!/usr/bin/env Rscript

    ### defining Nextflow environment variables as R variables
    ## input channel variables
    fwd_reads =         "${reads[0]}"
    rev_reads =         "${reads[1]}"
    sample_id =         "${meta.sample_id}"
    fcid =              "${meta.fcid}"
    target_gene =       "${meta.target_gene}"
    pcr_primers =       "${meta.pcr_primers}"
    
    ## global variables
    projectDir = "$projectDir"
    params_dict = "$params"
    
    ### source functions and themes, load packages, and import Nextflow params
    ### from "bin/process_start.R"
    sys.source("${projectDir}/bin/process_start.R", envir = .GlobalEnv)

    ### run module code
    sys.source(
        "${projectDir}/bin/$module_script", # run script
        envir = .GlobalEnv # this allows import of existing objects like projectDir
    )
    
    """

}