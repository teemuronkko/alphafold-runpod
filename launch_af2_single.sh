#!/bin/bash

Help()
{
  echo ""
  echo "Usage: $0 [input_fasta_path]"
  echo ""
  echo "  Submit an AlphaFold prediction job using a path to a fasta file."
  echo ""
  echo "  input_fasta_path : Path to a .fasta file containing multiple sequences."
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

# Get the number of available CPUs
NUM_CPUS=$(nproc)

# Get the number of available GPUs using NVIDIA's nvidia-smi command
NUM_GPUS=$(nvidia-smi --list-gpus | wc -l)

# Perform the division and round down using bc
N_CPUS=$(echo "scale=0; $NUM_CPUS / $NUM_GPUS" | bc)

echo "Number of available CPUs: $num_cpus"
echo "Number of available GPUs: $num_gpus"
echo "CPUs per GPU: $cpu_per_gpu"

# Ouptut dir 
AF_OUTPUT_DIR="/workspace/AF2_Models"
mkdir -p $AF_OUTPUT_DIR

# Go to AlphaFold 2 directory and activate required conda environment
cd $AF_DIR
source activate $AF_ENV

# Get start time for logging
start=`date +%s`

# Read in fasta files from the list
FASTAFILE=$1

# Variable for tracking start time of the prediction
pred_start=`date +%s`

# Path to features.pkl file
BASENAME=`basename $FASTAFILE .fasta`
FEATURES_PKL="${AF_OUTPUT_DIR}/${BASENAME}/features.pkl"

log_file="${AF_OUTPUT_DIR}/${BASENAME}/${BASENAME}_log.txt"
    
# Redirect standard output and standard error to the log file
exec > "${log_file}" 2>&1

echo -e "[$(date)] >> Job started at $(date) for ${BASENAME}"

# Check if pickle file exists and start prediction if so
if [ -e $FEATURES_PKL ]; then
    echo -e "\n[$(date)] >> ***** Starting prediction for $BASENAME *****"

    # Launch AF using the shell script
    $AF_DIR/run_alphafold.sh -d $AFDB_DIR -o $AF_OUTPUT_DIR -f $FASTAFILE -t "2023-01-01" -g true -r true -e true -n ${N_CPUS} -m multimer -c full_dbs -p true -l 1 -b false
else
    echo -e "[$(date)] >> ***** Prediction is skipped for $FASTAFILE because $FEATURES_PKL does not exist. *****"
fi

if [ -f "$AF_OUTPUT_DIR/$BASENAME/ranked_0.pdb" ]; then
    cp $AF_OUTPUT_DIR/$BASENAME/ranked_0.pdb $AF_OUTPUT_DIR/$BASENAME/${BASENAME}.pdb
    pred_end=`date +%s`
    pred_runtime=$((pred_end-pred_start))
    echo -e "[$(date)] >> ***** Prediction for $BASENAME finished in $pred_runtime seconds. *****"
elif [ -e $FEATURES_PKL ]; then 
    echo -e "[$(date)] >> ***** Prediction failed, or $AF_OUTPUT_DIR/$BASENAME/ranked_0.pdb doesn't exist. *****"
fi

end=`date +%s`
runtime=$((end-start))
echo -e "[$(date)] >> AF2 finished at $(date) for $BASENAME"
echo -e "[$(date)] >> Runtime: $runtime s"
exec >&-