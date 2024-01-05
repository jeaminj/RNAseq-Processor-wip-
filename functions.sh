#!/bin/bash
# v1.1 (wip)
# Interactive RNA-seq data processing command-line tool - FUNCTIONS File
# Author: Jeamin Jung

# Edit srr_numbers.txt with SRR Accession Numbers per line
srr_array=$(<srr_numbers.txt)

# DIRECTORY PATHS (Edit across diff users/systems)
source paths.sh

# Program [1]: Data Retrieval with prefetch and fasterq-dump
getSRRfiles () {
    user_choice=""
    echo =================================
    echo Sequence Retriever with SRATools 
    echo ================================= 
    echo "[1]" Download all SRA Files listed in srr_numbers.txt "[r]" Return to main menu
    echo "[2]" Download only manual input SRA File'(s)' "[q]" End program
    echo "--------------------------------"
    read user_choice
    if [ $user_choice == 1 ] # User selects to use srr_numbers.txt containing SRR accenssion numbers
    then
        cd $sraDir
        for srr in ${srr_array[@]};
        do
            echo Proceeding to fetch all SRA files listed in srr_numbers.txt
            echo Starting download of $srr
            prefetch $srr
            echo Beginning fasterq-dump, fastq files will be stored in $rawDataDir
            fasterq-dump $srr -O $rawDataDir
        done
    elif [ $user_choice == 2 ] # User selects to input SRR accenssion numbers
    then
        input_SRRs=()
        echo Enter the SRR Accession Numbers of SRA files you wish to retrieve, separated by spaces:
        echo Example: SRR101 SRR102 SRR103
        read -a input_SRRs
        
        for srr in ${input_SRRs[@]}; # Appending user input SRRs to srr_numbers.txt
        do
            echo $srr >> srr_numbers.txt
        done
    fi
    backToMenuOrQuit

}

# Program [2]: Quality Control with FASTQC (paired-end reads)
runQCmenu () {
    user_choice=""
    echo ============================ 
    echo Quality Control with FastQC 
    echo ============================ 
    echo "[1]" Run FastQC on all fastq files in a directory "[2]" Run FastQC only on select file'(s)' 
    echo "[r]" Return to main menu "  ""[q]" End program
    echo "---------------------------"
    read user_choice
    data_dir_path=""
    if [ "$user_choice" == 1 ] # FastQC on all .fastq files in a user defined directory
    then
        echo Enter root path of directory:
        echo Example: /home/projects/rawData
        read data_dir_path
        echo Running FastQC on all fastq files in $data_dir_path
        fastqc $data_dir_path/*
        multiqc $data_dir_path/.
        echo "FastQC done, reports stored in $data_dir_path"
    elif [ $user_choice == 2 ] # FastQC on user input files
    then
        echo Enter root path of directory where file is stored:
        echo Example: /home/projects/rawData
        read data_dir_path
        cd $data_dir_path
        srr_files=()
        echo ------
        echo Enter the accession number of the SRR.fastq file'(s)' to run FastQC on, separated by space: 
        echo Example: SRR101 SRR102
        echo "For paired-end reads, only the shared file name before '_1.fastq'/'_2.fastq' is needed"
        echo Example: Instead of entering both SRR101_1 SRR101_2, simply enter SRR101
        read -a srr_files
        for srr in ${srr_files[@]};
        do
            # Paired End Read Indexing 
            fq_fwd=${srr}_1.fastq
            fq_rev=${srr}_2.fastq
            # Forward reads
            if [ -f $data_dir_path/$fq_fwd ]  # Conditional test to check if file exists in directory
            then
                fastqc $data_dir_path/$fq_fwd -o $data_dir_path
            else
                echo "$data_dir_path/$fq_fwd" does not exist
            fi

            # Reverse reads
            if  [ -f $data_dir_path/$fq_rev ] # Conditional test to check if file exists in directory
            then
                fastqc $data_dir_path/$fq_rev -o $data_dir_path
            else
                echo $data_dir_path/$fq_rev does not exist
            fi

            # Single End Reads
            sr_file=${srr}.fastq
            if [ -f $data_dir_path/$sr_file ]
            then
                fastqc $data_dir_path/$sr_file
            else
                echo $data_dir_path/$sr_file does not exist
            fi
        done
    fi
    backToMenuOrQuit
}

# Program [3]: Trimming and Filtering with Fastp
trimANDfilter () {
    user_choice=""
    echo ================================== 
    echo Trimming and Filtering with fastp
    echo ==================================
    echo "[1]" Continue with all reads stored in a directory "[2]" Continue with only select file'(s)'
    echo "[r]" Return to main menu "[q]" End program
    echo "---------------------------------"
    read user_choice

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
    fi
    backToMenuOrQuit
}

# Program [4]: Alignment with HISAT2
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

# Program [5]: Quantification with ....
quantify () {
    echo pass
}

# Main Menu
startMenu () {
    user_choice=""
    echo -e "\n"Select a function to proceed:
    echo =============================================
    echo "[1]" SRA Downloader " [2]" Quality Control  "[3]" Trim and Filter  "[4]" Map to Reference 
    echo "[5]" Quantify Counts "[q]" Quit
    echo "---------------------------------------------"
    read user_choice
    
    if [ $user_choice == 1 ] 
    then
        getSRRfiles
    elif [ $user_choice == 2 ]
    then
        runQCmenu
    elif [ $user_choice == 3 ]
    then
        trimANDfilter
    elif [ $user_choice == 'q' ]
    then
        echo Closing program...
        exit
    else
        echo No valid selection made, ending program
        exit
    fi
}

backToMenuOrQuit() {
    if [ $user_choice == "r" ]       
    then
        startMenu
    elif [ $user_choice == "q" ] # Terminate script
    then
        echo Closing program...
        exit
    else
        echo No valid selection, closing program...
        exit
    fi 
}

# Script start-up program info. and interface
main () {
    echo -e "\033[1m_______________________________________________________________________\033[0m"
    echo -e "\n \033[1mRNAseq Data Processor by Jeamin Jung (v1.1), type 'h' for help\033[0m"
    echo -e "\033[1m_______________________________________________________________________\033[0m"
    echo -e "\n This program utilizes the following dependencies:"
    echo -e "\n sratools v2.10.9 | fastqc | multiqc | fastp | HISAT2 | FeatureCounts"
    echo -e "\n samtools | kallisto? |"
    echo _______________________________________________________________________
    startMenu
}
