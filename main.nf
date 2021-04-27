#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include {
	extract_data;
	file_has_extension
} from "./lib-nf/input"

inlude {
	GENOME
} from "./lib-nf/local/subworkflow/genome"

include {
	MUTECT
} from "./lib-nf/local/subworkflow/mutect"


tsv_path = null


ch_input_sample = Channel.empty ()


// check if we have valid --reads or --input
if (params.input == null) {
	  exit 1, "[MoCaSeq] error: --input was not supplied! Please check '--help' or documentation under 'running the pipeline' for details"
}

// Read in files properly from TSV file
if (params.input && (file_has_extension (params.input, "tsv"))) tsv_path = params.input


if (tsv_path) {

	tsv_file = file (tsv_path)
	if (tsv_file instanceof List) exit 1, "[MoCaSeq] error: can only accept one TSV file per run."
	if (!tsv_file.exists ()) exit 1, "[MoCaSeq] error: input TSV file could not be found. Does the file exist and is it in the right place? You gave the path: ${params.input}"
	ch_input_sample = extract_data (tsv_path)

} else exit 1, "[MoCaSeq] error: --input file(s) not correctly not supplied or improperly defined, see '--help' flag and documentation under 'running the pipeline' for details."

ch_branched_input = ch_input_sample.view ().branch {
	bam: it["Normal.BAM"] != 'NA' //These are all BAMs
}

//Removing R1/R2 in case of BAM input
ch_branched_input_bam = ch_branched_input.bam.map {
	m ->
    [m["Sample_Name"], m["Normal.BAM"]]
}

ch_branched_input_bam_human

workflow
{
	take:
		ch_branched_input_bam_human
	main:
	PREPARE_GENOME (params.genome_build.human)
	MUTECT (GENOME.out, ch_bam_channel)
}


