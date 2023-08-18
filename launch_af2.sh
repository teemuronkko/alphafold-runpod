#!/bin/bash

Help()
{
  echo ""
  echo "Usage: $0 [input_fasta_txt]"
  echo ""
  echo "  Submit an AlphaFold prediction job using a list file paths."
  echo ""
  echo "  input_fasta_txt : Path to a .txt file containing paths to one or more fasta files (one path per line) "
  echo ""
}

# Get the options
while getopts ":h" option; do
   case $option in
      h) # display Help
         Help
         exit;;
   esac
done

# AlphaFold paths and conda environment
AF_DIR="/workspace/alphafold-runpod"
AFDB_DIR="/workspace/alphafold-genetic-databases"
AF_ENV="/opt/conda/envs/af2_runpod"
N_CPUS=4

# Ouptut dir 
AF_OUTPUT_DIR="/workspace/AF2_Models"
mkdir -p $AF_OUTPUT_DIR

# Go to AlphaFold 2 directory and activate required conda environment
cd $AF_DIR
source activate $AF_ENV

# File containing paths to fasta files
FASTAPATHS=$1

# Iterate over line numbers using a for loop
N_LINES=$(wc -l < "$FASTAPATHS")
for (( i=1; i<=N_LINES; i++ )); do

    # Get start time for logging
    start=`date +%s`

    # Read in fasta files from the list
    FASTAFILE=$(sed -n "${i}p" "${FASTAPATHS}")

    # Variable for tracking start time of the prediction
    pred_start=`date +%s`

    # Path to features.pkl file
    BASENAME=`basename $FASTAFILE .fasta`
    FEATURES_PKL="${AF_OUTPUT_DIR}/${BASENAME}/features.pkl"

    log_file="${AF_OUTPUT_DIR}/${BASENAME}/${BASENAME}_log.txt"

    # Redirect standard output and standard error to the log file
    exec > "${log_file}" 2>&1

    echo -e ">> Job started at $(date) for ${BASENAME}"

    # Check if pickle file exists and start prediction if so
    if [ -e $FEATURES_PKL ]; then
        echo -e "\n>> ***** Starting prediction for $BASENAME *****"

        # Launch AF using the shell script
        $AF_DIR/run_alphafold.sh -d $AFDB_DIR -o $AF_OUTPUT_DIR -f $FASTAFILE -t "2023-01-01" -g true -r true -e false -n ${N_CPUS} -m multimer -c full_dbs -p true -l 1 -b false
        echo -e ">>"
    else
        echo -e ">> ***** Prediction is skipped for $FASTAFILE because $FEATURES_PKL does not exist. *****"
        echo -e ">>"
    fi

    if [ -f "$AF_OUTPUT_DIR/$BASENAME/ranked_0.pdb" ]; then
        cp $AF_OUTPUT_DIR/$BASENAME/ranked_0.pdb $AF_OUTPUT_DIR/$BASENAME/${BASENAME}.pdb
        pred_end=`date +%s`
        pred_runtime=$((pred_end-pred_start))
        echo -e ">> ***** Prediction for $BASENAME finished in $pred_runtime seconds. *****"
        echo -e ">>"
    elif [ -e $FEATURES_PKL ]; then 
        echo -e ">> ***** Prediction failed, or $AF_OUTPUT_DIR/$BASENAME/ranked_0.pdb doesn't exist. *****"
        echo -e ">>"
    fi

    end=`date +%s`
    runtime=$((end-start))
    echo -e ">> AF2 finished at $(date) for $BASENAME"
    echo -e ">> Runtime: $runtime s"
    exec >&-
done
