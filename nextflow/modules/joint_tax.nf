process JOINT_TAX {
    def module_name = "joint_tax"
    tag "$fcid; $pcr_primers"
    // label:  

    input:
    tuple val(fcid), val(pcr_primers), val(target_gene), path(idtaxa_db), path(ref_fasta), path(tax), path(blast), path(seqtab)
    
    output:
    tuple val(fcid), val(pcr_primers), path("*_taxblast.rds"), emit: taxtab

    publishDir "${projectDir}/output/modules/${module_name}", mode: 'copy'

    // when: 

    script:
    def module_script = "${module_name}.R"
    """
    #!/usr/bin/env Rscript

    ### defining Nextflow environment variables as R variables
    ## input channel variables
    fcid =                  "${fcid}"
    pcr_primers =           "${pcr_primers}"
    target_gene =           "${target_gene}"
    idtaxa_output =         "${tax}"
    blast_output =          "${blast}"
    seqtab =                "${seqtab}"
    
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
    
    ### save .RData for debugging
    if ("${params.rdata}" == "true") {
        save.image()
    } else {
        NULL
    }

    """

}