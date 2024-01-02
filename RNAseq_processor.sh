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
    echo Select "[1]" Run FastQC on all fastq files in $sraDir "[2]" Input manual file'(s)' selection "[r]" Return to menu
    echo "---------------------------"
    read user_sel
    if [ "$user_sel" == 1 ] # FastQC on all .fastq files in /rawData
    then
        cd $rawDataDir
        fastqc *
        multiqc .
        echo "FastQC done, reports stored in $rawDataDir"
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
    echo "[1]" Continue with all reads stored in $rawDataDir "[2]" Continue with manual input'(s)' "[r]" Return to menu
    echo "---------------------------------"
    read user_choice

    if [ $user_choice == 1 ]
    then
        echo pass
    elif [ $user_choice == 2 ] # Only runs fastp on user input files
    then
        manual_inputs=()
        echo Enter srr file'(s)' you wish to trim and filter, separated by space:
        read manual_inputs
        for srr_file in ${manual_inputs[@]};
        do
            echo Starting fastp for $srr_file
        done
            
    fi

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