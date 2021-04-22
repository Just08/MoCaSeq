#!/bin/bash

##########################################################################################
##
## CNV_RunHMMCopy.sh
##
## Run HMMCopy und matched tumour-normal .bam-files.
##
##########################################################################################

name=$1
species=$2
config_file=$3
runmode=$4
resolution=$5 # window size for the CNV estimation; usually between 1000 and 20000 (depending on the sequencing coverage)
types=$6

. $config_file

chromosomes=$(echo "${chromosome_names}" | tr " " ",")

if [ $runmode = 'MS' ]; then
	types="Tumor Normal"
fi

for type in $types;
do
	(
	echo "Binning read counts in $type file @ $resolution resolution..."
	echo "Binning read counts for ${chromosomes}..."
	# readCounter requires indices as .bam.bai (there is a -b option to build them automatically but it doesn't check if they exist first)
	$hmmcopyutils_dir/bin/readCounter -w $resolution -q20 -c $chromosomes $name/results/bam/$name.$type.bam > $name/results/HMMCopy/$name.$type.$resolution.wig
	) &
done

wait
