/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// include { paramsSummaryLog; paramsSummaryMap; fromSamplesheet } from 'plugin/nf-validation'
// this allows 'fromSamplesheet' command to pull data from samplesheet file

// def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
// def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
// def summary_params = paramsSummaryMap(workflow)

// // Print parameter summary log to screen
// log.info logo + paramsSummaryLog(workflow) + citation

// WorkflowAmpliseq.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
// ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
// ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
// ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

// TODO: What channels do I need for config? This could be used to define custom visualisation or output summary formats
// TODO: Set maximum number of cores/cpus at the total number of read pairs/samples

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    INPUT AND VARIABLES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


// Input

// directory in projectDir where data files are stored; "test_data" for test data
// def data_loc = "test_data" // not needed as parameters are parsed in R script

// report sources

// Set non-params Variables

// // create directory where channel output can be stored for debugging
// channelDir = file('./output/channels')
// channelDir.mkdirs()


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PARAMETER_SETUP                           } from '../modules/parameter_setup'
include { SEQ_QC                                    } from '../modules/seq_qc'
include { SPLIT_LOCI                                } from '../modules/split_loci'
include { PRIMER_TRIM                               } from '../modules/primer_trim'
include { READ_FILTER                               } from '../modules/read_filter' 
include { FILTER_QUALPLOTS as FILTER_QUALPLOTS_PRE  } from '../modules/filter_qualplots'
include { FILTER_QUALPLOTS as FILTER_QUALPLOTS_POST } from '../modules/filter_qualplots'
include { ERROR_MODEL as ERROR_MODEL_F              } from '../modules/error_model'
include { ERROR_MODEL as ERROR_MODEL_R              } from '../modules/error_model'
include { DENOISE as DENOISE1_F                     } from '../modules/denoise'
include { DENOISE as DENOISE1_R                     } from '../modules/denoise'
include { DADA_PRIORS as DADA_PRIORS_F              } from '../modules/dada_priors'
include { DADA_PRIORS as DADA_PRIORS_R              } from '../modules/dada_priors'
include { DENOISE as DENOISE2_F                     } from '../modules/denoise'
include { DENOISE as DENOISE2_R                     } from '../modules/denoise'
include { DADA_MERGEREADS                           } from '../modules/dada_mergereads'
include { FILTER_SEQTAB                             } from '../modules/filter_seqtab'
include { TAX_IDTAXA                                } from '../modules/tax_idtaxa'
include { TAX_BLAST                                 } from '../modules/tax_blast'
include { JOINT_TAX                                 } from '../modules/joint_tax'
include { MERGE_TAX                                 } from '../modules/merge_tax'
include { ASSIGNMENT_PLOT                           } from '../modules/assignment_plot'
include { TAX_SUMMARY                               } from '../modules/tax_summary'
include { TAX_SUMMARY_MERGE                         } from '../modules/tax_summary_merge'
// include { MERGE_SEQTAB                              } from '../modules/merge_seqtab'
include { PHYLOSEQ_UNFILTERED                       } from '../modules/phyloseq_unfiltered'
// include { PHYLOSEQ_SUMMARY                          } from '../modules/phyloseq_summary'
// include { ACCUMULATION_CURVE                        } from '../modules/accumulation_curve'
// include { PHYLOSEQ_FILTER                           } from '../modules/phyloseq_filter'
// include { READ_TRACKING                             } from '../modules/read_tracking'



//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//

// include { PARSE_INPUT                   } from '../subworkflows/local/parse_input'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//

// include { FASTQC                            } from '../modules/nf-core/fastqc/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIPERLINE {

    // ch_versions = Channel.empty()

    //
    // Create input channels
    //


    //// input samplesheet and loci parameters
    PARAMETER_SETUP ( )

    //// parse samplesheets that contain locus-specific parameters
    PARAMETER_SETUP.out.samdf_locus
        .flatten ()
        .splitCsv ( header: true )
        .map { row -> 
            def meta = row.subMap(
                'sample_id','sample_name','extraction_rep','amp_rep',
                'client_name','experiment_name','sample_type','collection_method',
                'collection_location','lat_lon','environment','collection_date',
                'operator_name','description','assay','extraction_method',
                'amp_method','target_gene','pcr_primers','for_primer_seq',
                'rev_primer_seq','index_plate','index_well','i7_index_id',
                'i7_index','i5_index_id','i5_index','seq_platform',
                'fcid','for_read_length','rev_read_length','seq_run_id',
                'seq_id','seq_date','analysis_method','notes',
                'base','max_primer_mismatch','read_min_length','read_max_length',
                'read_max_ee','read_trunc_length','read_trim_left','read_trim_right',
                'asv_min_length','asv_max_length','high_sensitivity','concat_unmerged','genetic_code','coding',
                'phmm','idtaxa_db','ref_fasta','idtaxa_confidence',
                'run_blast','blast_min_identity','blast_min_coverage','target_kingdom',
                'target_phylum','target_class','target_order','target_family',
                'target_genus','target_species','min_sample_reads','min_taxa_reads',
                'min_taxa_ra','threads'
                )
                [ meta, [
                    file(row.fwd, checkIfExists: true),
                    file(row.rev, checkIfExists: true)
                ]]  
            }
        .set { ch_sample_locus_reads }

    //// get names and count of the multiplexed loci used
    PARAMETER_SETUP.out.samdf_locus
        .flatten ()
        .splitCsv ( header: true )
        .map { row -> row.target_gene }
        .unique ()
        .toList ()
        .set { ch_loci_names } // value channel; list

    ch_loci_names
        .flatten ()
        .count ()
        .set { ch_loci_number } // value channel; integer


    //// get names of flow cells ('fcid') as channel
    // extract fcid from metadata
    ch_sample_locus_reads 
        .map { meta, reads ->
            def fcid = meta.fcid
            return tuple(fcid, reads) } 
        .groupTuple() 
        .set { ch_sample_reads_fcid }
    
    // extract flow cell IDs as channel
    ch_sample_reads_fcid 
        .map { group -> group[0] }
        .set { ch_fcid }

    // create channel linking pcr_primers and databases (from params)
    ch_sample_locus_reads 
        .map { meta, reads -> 
                [ meta.pcr_primers, meta.target_gene, meta.idtaxa_db, meta.ref_fasta ] }
        .unique()
        .set { ch_loci_info }

    //// create channel of loci parameters
    PARAMETER_SETUP.out.loci_params // loci_params.csv file with one row per primer pair
        .splitCsv ( header: true )
        .map { row -> 
                [ row.pcr_primers, row ] }
        .set { ch_loci_params } // cardinality: pcr_primers, map(all params, incl. pcr_primers)


    // run SEQ_QC per flow cell 
    // SEQ_QC ( ch_fcid ) // optional step for testing

    /// TODO: develop method to count reads as they move through the pipeline
    //      ie. input file, after splitting, after primer trimming, after qual trim etc.

    //// split sample reads by locus (based on primer seq.)
    SPLIT_LOCI ( ch_sample_locus_reads ) 

    //// trim primer sequences from the start and end of reads
    PRIMER_TRIM ( SPLIT_LOCI.out.reads )

    //// filter reads using dada2 and input parameters
    READ_FILTER ( PRIMER_TRIM.out.reads )

    //// create plots of read quality pre- and post-filtering, per flowcell (optional)
    // FILTER_QUALPLOTS_PRE ( PRIMER_TRIM.out.reads )

    // FILTER_QUALPLOTS_POST ( READ_FILTER.out.reads )

    /// TODO: Use FILTER_QUALPLOTS_COMBINE to combine plots by fcid and type into one PDF


    ///// split filtered reads into lists of reads per flowcell, primers and direction
    //// forward read channel
    READ_FILTER.out.reads
        .map { meta, reads -> 
                [ "forward", meta.pcr_primers, meta.fcid, reads[0] ] }
        .groupTuple( by: [0,1,2] )
        .set { ch_error_input_fwd }

    //// reverse read channel
    READ_FILTER.out.reads
        .map { meta, reads -> 
                [ "reverse", meta.pcr_primers, meta.fcid, reads[1] ] }
        .groupTuple ( by: [0,1,2] )
        .set { ch_error_input_rev }


    //// error model on forward reads
    ERROR_MODEL_F ( ch_error_input_fwd )

    //// error model on reverse reads
    ERROR_MODEL_R ( ch_error_input_rev )

    //// input channel for denoising forward reads
    READ_FILTER.out.reads
        .map { meta, reads -> 
                [ "forward", meta.pcr_primers, meta.fcid, meta, reads[0] ] }
        .combine ( ERROR_MODEL_F.out.errormodel, by: [0,1,2] ) // combine with error model
        .map { direction, pcr_primers, fcid, meta, reads, errormodel -> // add empty file path for priors
                [ direction, pcr_primers, fcid, meta, reads, errormodel, "$projectDir/assets/NO_FILE" ] }
        .set { ch_denoise_input_forward }

    // ch_denoise_input_forward .view ()

    //// input channel for denoising reverse reads
    READ_FILTER.out.reads
        .map { meta, reads -> 
                [ "reverse", meta.pcr_primers, meta.fcid, meta, reads[1] ] }
        .combine ( ERROR_MODEL_R.out.errormodel, by: [0,1,2] ) // combine with error model
        .map { direction, pcr_primers, fcid, meta, reads, errormodel -> // add empty file path for priors
                [ direction, pcr_primers, fcid, meta, reads, errormodel, "$projectDir/assets/NO_FILE" ] }
        .set { ch_denoise_input_reverse }


    //// first pass of denoising per flowcell, primer and sample
    DENOISE1_F ( ch_denoise_input_forward, "first" )
    
    //// denoise forward reads per flowcell, primer and sample
    DENOISE1_R ( ch_denoise_input_reverse, "first" )

    // high sensitivity mode condition
    if ( params.high_sensitivity ) { // run prior extraction and second pass denoising
        //// group priors for each read file
        /// forward reads
        DENOISE1_F.out.seq
            .map { direction, pcr_primers, fcid, meta, reads, priors ->
                    [ direction, pcr_primers, fcid, priors ] }
            .groupTuple ( by: [0,1,2] )
            .set { ch_priors_f_pre }

        /// reverse reads
        DENOISE1_R.out.seq
            .map { direction, pcr_primers, fcid, meta, reads, priors ->
                    [ direction, pcr_primers, fcid, priors ] }
            .groupTuple ( by: [0,1,2] )
            .set { ch_priors_r_pre }

        //// get priors for forward reads
        DADA_PRIORS_F ( ch_priors_f_pre )
        
        /// combine with forward read data channel
        ch_denoise_input_forward
            .map { direction, pcr_primers, fcid, meta, reads, errormodel, priors -> // remove null priors
                    [ direction, pcr_primers, fcid, meta, reads, errormodel ] }
            .combine ( DADA_PRIORS_F.out.priors, by: [0,1,2] )
            .set { ch_denoise2_input_forward }

        //// get priors for reverse reads
        DADA_PRIORS_R ( ch_priors_r_pre )

        /// combine with reverse read data channel
        ch_denoise_input_reverse
            .map { direction, pcr_primers, fcid, meta, reads, errormodel, priors -> // remove null priors
                    [ direction, pcr_primers, fcid, meta, reads, errormodel ] }
            .combine ( DADA_PRIORS_R.out.priors, by: [0,1,2] )
            .set { ch_denoise2_input_reverse }

        //// run pseudo-pooled 2nd denoising with priors on forward reads
        DENOISE2_F ( ch_denoise2_input_forward, "second" )

        //// run pseudo-pooled 2nd denoising with priors on reverse reads
        DENOISE2_R ( ch_denoise2_input_reverse, "second" )

        /// join F and R denoise2 outputs
        // prepare forward reads
        DENOISE2_F.out.seq
            .map { direction, pcr_primers, fcid, meta, readsF, seqF ->
                    [ meta.sample_id, pcr_primers, fcid, meta, readsF, seqF ] }
            .set { ch_seq_forward }

        // prepare reverse reads
        DENOISE2_R.out.seq
            .map { direction, pcr_primers, fcid, meta, readsR, seqR ->
                    [ meta.sample_id, pcr_primers, fcid, meta, readsR, seqR ] }
            .set { ch_seq_reverse }

        // join
        ch_seq_forward
            .combine ( ch_seq_reverse, by: [0,1,2,3] ) // combine by sample_id
            .map { sample_id, pcr_primers, fcid, meta, readsF, seqF, readsR, seqR -> // remove sample_id and meta
                    [ pcr_primers, fcid, meta.concat_unmerged, meta,
                    file(readsF, checkIfExists: true),
                    file(readsR, checkIfExists: true), 
                    file(seqF, checkIfExists: true),
                    file(seqR, checkIfExists: true) ] } 
            .groupTuple ( by: [0,1,2] ) // assumes concat_unmerged is the same for all samples, which it should be
            .set { ch_seq_combined }

    } else { // don't run second denoising step with priors
        /// join F and R DENOISE1 outputs
        // prepare forward reads
        DENOISE1_F.out.seq
            .map { direction, pcr_primers, fcid, meta, readsF, seqF ->
                    [ meta.sample_id, pcr_primers, fcid, meta, readsF, seqF ] }
            .set { ch_seq_forward }

        // prepare reverse reads
        DENOISE1_R.out.seq
            .map { direction, pcr_primers, fcid, meta, readsR, seqR ->
                    [ meta.sample_id, pcr_primers, fcid, meta, readsR, seqR ] }
            .set { ch_seq_reverse }

        // join
        ch_seq_forward
            .combine ( ch_seq_reverse, by: [0,1,2,3] ) // combine by sample_id
            .map { sample_id, pcr_primers, fcid, meta, readsF, seqF, readsR, seqR -> // remove sample_id and meta
                    [ pcr_primers, fcid, meta.concat_unmerged, meta,
                    file(readsF, checkIfExists: true),
                    file(readsR, checkIfExists: true), 
                    file(seqF, checkIfExists: true),
                    file(seqR, checkIfExists: true) ] } 
            .groupTuple ( by: [0,1,2] ) // assumes concat_unmerged is the same for all samples
            .set { ch_seq_combined }
    }

    //// merge paired-end reads per flowcell x locus combo
    DADA_MERGEREADS ( ch_seq_combined )

    //// filter sequence table
    FILTER_SEQTAB ( DADA_MERGEREADS.out.seqtab )
    ch_seqtab = FILTER_SEQTAB.out.seqtab
        .map { pcr_primers, fcid, meta, seqtab -> // remove meta
            [ pcr_primers, fcid, seqtab ] }

    //// use IDTAXA to assign taxonomy
    TAX_IDTAXA ( FILTER_SEQTAB.out.seqtab )
    ch_tax_idtaxa_tax = TAX_IDTAXA.out.tax
        .map { pcr_primers, fcid, meta, tax -> // remove meta
            [ pcr_primers, fcid, tax ] }
    ch_tax_idtaxa_ids = TAX_IDTAXA.out.ids 
        .map { pcr_primers, fcid, meta, ids -> // remove meta
            [ pcr_primers, fcid, ids ] }

    //// use blastn to assign taxonomy
    TAX_BLAST ( FILTER_SEQTAB.out.seqtab )
    ch_tax_blast = TAX_BLAST.out.blast
        .map { pcr_primers, fcid, meta, blast -> // remove meta
            [ pcr_primers, fcid, blast ] }

    //// merge tax assignment outputs and filtered seqtab (pre-assignment)
    ch_tax_idtaxa_tax
        .combine ( ch_tax_blast, by: [0,1] ) 
        .combine ( ch_seqtab, by: [0,1] )
        .combine ( ch_loci_params, by: 0 ) // adds map of loci_params
        .set { ch_joint_tax_input } // pcr_primers, fcid, tax, blast, seqtab, loci_params

    // ch_joint_tax_input.view()

    //// aggregate taxonomic assignment
    JOINT_TAX ( ch_joint_tax_input )

    //// group taxtab across flowcells (per locus)
    JOINT_TAX.out.taxtab
        .groupTuple ( by: 0 ) // group into tuples using pcr_primers
        .set { ch_mergetax_input }

    //// merge tax tables across flowcells
    MERGE_TAX ( ch_mergetax_input )

    //// create assignment_plot input merging filtered seqtab, taxtab, and blast output
    /// channel has one item per fcid x pcr_primer combo
    ch_seqtab
        .combine ( TAX_BLAST.out.blast_assignment, by: [0,1] ) // combine by pcr_primers, fcid 
        .combine ( JOINT_TAX.out.taxtab, by: [0,1] ) // combine by pcr_primers, fcid
        .combine ( ch_loci_params, by: 0 ) // add loci info (TODO: use ch_loci_params [stripped down] instead)
        .set { ch_assignment_plot_input }
        
    //// do assignment plot
    ASSIGNMENT_PLOT ( ch_assignment_plot_input )

    /// generate taxonomic assignment summary per locus (also hash seq)
    ch_tax_idtaxa_tax // pcr_primers, fcid, "*_idtaxa_tax.rds"
        .combine ( ch_tax_idtaxa_ids, by: [0,1] ) // + "*_idtaxa_ids.rds"
        .combine ( ASSIGNMENT_PLOT.out.joint, by: [0,1] ) // + "*_joint.rds", map(loci_params)
        .set { ch_tax_summary_input }

    //// create taxonomic assignment summaries per locus x flowcell
    TAX_SUMMARY ( ch_tax_summary_input )

    // create channel containing a single list of all TAX_SUMMARY outputs
    TAX_SUMMARY.out.rds
        .map { pcr_primers, fcid, loci_params, tax_summary ->
            [ tax_summary ] } 
        .collect()
        .set { ch_tax_summaries } 

    //// merge TAX_SUMMARY outputs together across loci and flow cells
    TAX_SUMMARY_MERGE ( ch_tax_summaries )
    
    //// inputs for PHYLOSEQ_UNFILTERED
    /*
    - MERGE_TAX output (tax tables per locus)
        - MERGE_TAX.out.merged_tax == pcr_primers, list("[pcr_primers]_merged_tax.rds")
    - FILTER_SEQTAB output (ch_seqtab; sequence tables per locus x flowcell)
        - ch_seqtab == pcr_primers, fcid, "*_seqtab.cleaned.rds"
    - samplesheet (PARAMETER_SETUP.out.samdf_params; a .csv file)
    - 
    
    - per locus parameters: target_kingdom, target_phylum, target_class,
    target_order, target_family, target_genus, target_species, 
    min_sample_reads, min_taxa_reads, min_taxa_ra

    - NOTE: Need to include hashes! 
    */

    ch_taxtables_locus = MERGE_TAX.out.merged_tax // pcr_primers, path("*_merged_tax.rds")

    ch_seqtables_locus = ch_seqtab
        .map { pcr_primers, fcid, seqtab -> [ pcr_primers, seqtab ] } // remove fcid field
        .groupTuple ( by: 0 ) 
    
    // combine taxtables, seqtables and parameters
    ch_taxtables_locus
        .combine ( ch_seqtables_locus, by: 0 )
        .combine ( ch_loci_params, by: 0 )
        .set { ch_phyloseq_input }

    /// parsing loci-specific samplesheets
    PARAMETER_SETUP.out.samdf_locus
        .flatten()
        .map { csv -> 
            csv.toString()    }
        .view()

    //// create phyloseq objects across all flowcells and loci; output unfiltered summary tables and accumulation curve plot
    PHYLOSEQ_UNFILTERED ( ch_phyloseq_input, PARAMETER_SETUP.out.samdf )

    //// apply taxonomic and minimum abundance filtering per locus (from loci_params), then combine to output filtered summary tables
    // PHYLOSEQ_FILTER ( , ch_loci_params )


    //// move final output files to the output report directory

}
