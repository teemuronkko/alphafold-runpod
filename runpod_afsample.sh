#!/bin/bash -l
source ~/.bashrc
source activate afsample
conda activate afsample

# Required input: fasta file and path to the output folder (subfolder will be created)
fasta=$1
outfolder=$2 

# Get basename of the input fasta file 
BASENAME=`basename $fasta .fasta`

# Path to AF2 directory
AF_path="./"

# nstruct * 30 models will be generated, default: nstruct=200
nstruct=200

#generate 10 x nstruct models using v1 & v2 using dropout and templates
python $AF_path/run_alphafold_pkl.py --db_preset=full_dbs --model_preset multimer_all --fasta_paths $fasta --output_dir $outfolder/ --nstruct $nstruct --dropout=True

#generate 10 x nstruct models using v1 & v2 using dropout and notemplates, the --suffix ensures the model names are different since outfolder is the same
python $AF_path/run_alphafold_pkl.py --db_preset=full_dbs --model_preset multimer_all --fasta_paths $fasta --output_dir $outfolder/ --nstruct $nstruct --dropout=True --dropout_structure_module=False --no_templates --suffix no_templates

#generate 5 x nstruct models using v1 using dropout, notemplates, recycles 21, the --suffix ensures the model names are different since outfolder is the same
python $AF_path/run_alphafold_pkl.py --db_preset=full_dbs --model_preset multimer_v1 --fasta_paths $fasta --output_dir $outfolder/ --nstruct $nstruct --dropout=True --dropout_structure_module=False --no_templates --max_recycles 21 --suffix no_templates_r21

#generate 5 x nstruct models using v2 using dropout, notemplates, recycles 9, the --suffix ensures the model names are different since outfolder is the same
python $AF_path/run_alphafold_pkl.py --db_preset=full_dbs --model_preset multimer_v2 --fasta_paths $fasta --output_dir $outfolder/ --nstruct $nstruct --dropout=True --dropout_structure_module=False --no_templates --max_recycles 9 --suffix no_templates_r9
