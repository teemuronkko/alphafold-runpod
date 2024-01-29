#!/bin/bash -l

source ~/.bashrc
conda activate afsample

fasta=$1
outfolder=$2

# Get basename of the input fasta file
BASENAME=`basename $fasta .fasta`

AF_path="./"

#get the score for all models and return a sorted scorefile.
python $AF_path/scores_from_json.py $fasta $outfolder/ > $outfolder/$BASENAME/scores.sc

#Relax the first model N first
N=5
for pkl in `head -n $N $outfolder/$BASENAME/scores.sc | awk '{print $2}'`
do
    python $AF_path/run_relax_from_results_pkl.py $pkl
done
