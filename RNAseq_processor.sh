#!/bin/bash
# v1.1 (wip)
# Interactive RNA-seq data processing command-line tool 
# Author: Jeamin Jung


srr_array=()

# DIRECTORY PATHS (Change as necessary)
sraDir=/home/xx_rnaseq/sra
rawDataDir=/home/xx_rnaseq/rawData
wd=/home/xx_rnaseq

# Program [1]: Data Retrieval with prefetch and fasterq-dump
getSRA () {
    echo =================================
    echo Sequence Retriever with SRATools 
    echo ================================= 
    echo "[r]" Return to menu
    echo "--------------------------------"
    echo Enter SRR Accession Numbers you wish to retrieve, separated by spaces:
    echo Example: SRR101 SRR102 SRR103 

    read -a srr_array 

    if [ $srr_array == 'r' ] 
    then
        startMenu
    fi

    cd $sraDir
    for srr in ${srr_array[@]};
    do
        echo Proceeding to download $srr
        prefetch $srr
        echo "Begginning fasterq-dump, fastq files will be stored in" $rawDataDir
        fasterq-dump $srr -O $rawDataDir
    done
}

# Program [2]: Quality Control with FASTQC (paired-end reads)
runQCmenu () {
    user_sel=""
    echo ============================ 
    echo Quality Control with FastQC 
    echo ============================ 
    echo Select "[1]" Run FastQC on all fastq files in a directory "[2]" Run FastQC only on select file'(s)' "[r]" Return to menu
    echo "---------------------------"
    read user_sel
    if [ "$user_sel" == 1 ] # FastQC on all .fastq files in /rawData
    then
        data_dir_path=""
        echo Enter directory path:
        echo Example: /home/projects/rawData
        read data_dir_path
        echo Running FastQC on all fastq files in $data_dir_path
        fastqc $data_dir_path/*
        multiqc $data_dir_path/.
        echo "FastQC done, reports stored in $data_dir_path"
    elif [ $user_sel == 2 ] # FastQC on user input 
    then
        cd $rawDataDir
        srr_files=()
        echo Enter SRR.fastq files to run FastQC on, separated by space: 
        echo Example: SRR101_1.fastq SRR101_2.fastq
        read srr_file
        for srr in ${srr_files[@]};
        do
            fastqc $srr
        done
    elif [ $user_sel == 'r' ] # Return to menu
    then
        startMenu
    fi  
}

# Program [3]: Trimming and Filtering with Fastp
trimReads () {
    user_choice=""
    echo ================================== 
    echo Trimming and Filtering with fastp
    echo ==================================
    echo "[1]" Continue with all reads stored in $rawDataDir "[2]" Continue with only select file'(s)'
    echo "[3]" Continue with all reads stored in a different directory "  ""[r]" Return to menu
    echo "---------------------------------"
    read user_choice

    # **Need to add SE or PE selection capability**
    # Currently written for PE reads only
    if [ $user_choice == 1 ] # Runs fastp on all raw reads (raw data directory)
    then
        SECONDS=0
        srrArray=()
        output_dir=""
        min_length=""
        echo Enter only SRR Accenssion Numbers of fastq files, separated by space
        echo Example: SRR101 SRR102 SRR103 SRR104
        read srrArray

        echo Enter minimum length of reads to filter: 
        read min_length

        echo Enter path of desired output directory:
        echo Example: /home/projects/data/trimmedData
        read output_dir
        for srr in ${srrArray[@]};
        do
            #For paired end reads
            fq_fwd=${srr}_1.fastq
            fq_rev=${srr}_2.fastq

            fastp \
            -i $rawDataDir/$fq_fwd \
            -I $rawDataDir/$fq_rev \
            --out1 $output_dir/${srr}_trimmed_1P.fastq \
            --out2 $output_dir/${srr}_trimmed_2P.fastq \
            --length_required $min_length

        done
        duration=SECONDS
        echo Trimming and Filtering Complete, outputs stored in $output_dir
        echo "$((duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

    elif [ $user_choice == 2 ] # Only runs fastp on select user input files
    then
        manual_inputs=()
        echo Enter srr file'(s)' you wish to trim and filter, separated by space:
        read manual_inputs
        for srr_file in ${manual_inputs[@]};
        do
            echo Starting fastp for $srr_file
        done
    elif [ $user_choice == 3 ]       
    then
        diff_dir_path=""
        echo Enter path of directory: 
        echo Example: /home/projects/xx_rnaseq/data/trimmedData
        read diff_dir_path
    fi

}

alignToGenome () {
    user_choice=""
    echo ================================== 
    echo Aligning to Genome with HiSAT2 
    echo ==================================
    echo "[1]" Continue with all reads stored in $rawDataDir "[2]" Continue with only select file'(s)'
    echo "[3]" Continue with all reads stored in a different directory "  ""[r]" Return to menu
    echo "---------------------------------"
    read user_choice
}

quantify () {
    echo pass
}

startMenu () {
    user_choice=""
    echo -e "\n"Select a function to proceed:
    echo =============================================
    echo "[1]" SRA Downloader "[2]" Quality Control "[3]" Trim and Filter "[4]" Map to Reference \
         "[5]" Quantify Counts "[q]" Quit
    echo "---------------------------------------------"
    read user_choice
    
    if [ $user_choice == 1 ] 
    then
        getSRA
    elif [ $user_choice == 2 ]
    then
        runQCmenu
    elif [ $user_choice == 3 ]
    then
        trimReads
    else
        echo No selection made, ending program
    fi
}

main () {
    echo _______________________________________________________________________
    echo -e "\n RNAseq Data Processor by Jeamin Jung (v1.1), type 'h' for help"
    echo _______________________________________________________________________
    echo -e "\n This program requires the following dependencies:"
    echo -e "\n sratools v2.10.9 | fastqc | multiqc | fastp | HISAT2 | FeatureCounts"
    echo _______________________________________________________________________
    startMenu
}

main