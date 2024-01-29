#!/bin/bash -l
#SBATCH --job-name=AFsample 
#SBATCH --mem=100G
#SBATCH --partition=page
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --output=/groups/scienceai/tronkko/temp/logs/%j_out.txt
#SBATCH --error=/groups/scienceai/tronkko/temp/logs/%j_err.txt
#SBATCH --nodelist=node263

source ~/.bashrc
conda activate afsample

module load astro
module load cuda/11.2

# Export cuda environment variables
export CUDA_HOME=/software/astro/cuda/11.2/
export PATH=/software/astro/cuda/11.2//bin/${PATH:+:${PATH}}$
export CPATH=/software/astro/cuda/11.2/include:$CPATH
export LIBRARY_PATH=/software/astro/cuda/11.2//lib64:$LIBRARY_PATH
export LD_LIBRARY_PATH=/software/astro/cuda/11.2/lib64/${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}$

# Export ENVIRONMENT variables and set CUDA devices for use
# CUDA GPU control
export CUDA_VISIBLE_DEVICES=0

# TensorFlow control
export TF_FORCE_UNIFIED_MEMORY='1'

# JAX control
export XLA_PYTHON_CLIENT_MEM_FRACTION='4.0'

# Required input: fasta file and path to the output folder (subfolder will be created)
fasta=$1
outfolder=$2 

# Get basename of the input fasta file 
BASENAME=`basename $fasta .fasta`

# Set directory where databases and parameters are stored
DOWNLOAD_DIR="/groups/scienceai/tronkko/alphafold-genetic-databases"

AF_path=/groups/scienceai/tronkko/alphafoldv2.2.0

# Flags for databases
std_flags="
--db_preset=full_dbs
--uniref90_database_path=$DOWNLOAD_DIR/uniref90/uniref90.fasta
--mgnify_database_path=$DOWNLOAD_DIR/mgnify/mgy_clusters_2023_02.fa
--bfd_database_path=$DOWNLOAD_DIR/bfd/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt
--uniclust30_database_path=$DOWNLOAD_DIR/uniref30/UniRef30_2023_02/UniRef30_2023_02
--uniprot_database_path=$DOWNLOAD_DIR/uniprot/uniprot.fasta
--pdb_seqres_database_path=$DOWNLOAD_DIR/pdb_seqres/pdb_seqres.txt
--template_mmcif_dir=$DOWNLOAD_DIR/pdb_mmcif/mmcif_files
--obsolete_pdbs_path=$DOWNLOAD_DIR/pdb_mmcif/obsolete.dat
"

# nstruct * 30 models will be generated, default: nstruct=200
nstruct=200

#generate 10 x nstruct models using v1 & v2 using dropout and templates
python $AF_path/run_alphafold_pkl.py $std_flags --model_preset multimer_all --fasta_paths $fasta --output_dir $outfolder/ --nstruct $nstruct --dropout=True

#generate 10 x nstruct models using v1 & v2 using dropout and notemplates, the --suffix ensures the model names are different since outfolder is the same
python $AF_path/run_alphafold_pkl.py $std_flags --model_preset multimer_all --fasta_paths $fasta --output_dir $outfolder/ AF_models_dropout/ --nstruct $nstruct --dropout=True --dropout_structure_module=False --no_templates --suffix no_templates

#generate 5 x nstruct models using v1 using dropout, notemplates, recycles 21, the --suffix ensures the model names are different since outfolder is the same
python $AF_path/run_alphafold_pkl.py $std_flags --model_preset multimer_v1 --fasta_paths $fasta --output_dir $outfolder/ --nstruct $nstruct --dropout=True --dropout_structure_module=False --no_templates --max_recycles 21 --suffix no_templates_r21

#generate 5 x nstruct models using v2 using dropout, notemplates, recycles 9, the --suffix ensures the model names are different since outfolder is the same
python $AF_path/run_alphafold_pkl.py $std_flags --model_preset multimer_v2 --fasta_paths $fasta --output_dir $outfolder/ --nstruct $nstruct --dropout=True --dropout_structure_module=False --no_templates --max_recycles 9 --suffix no_templates_r9

#get the score for all models and return a sorted scorefile.
python $AF_path/scores_from_json.py $fasta $outfolder/ > $outfolder/$BASENAME/scores.sc

#Relax the first model N first
N=5
for pkl in `head -n $N $outfolder/$BASENAME/scores.sc | awk '{print $2}'`
do
    python $AF_path/run_relax_from_results_pkl.py $pkl
done

mv "/groups/scienceai/tronkko/temp/logs/${SLURM_JOB_ID}_err.txt" "${outfolder}/${BASENAME}/prediction_${SLURM_JOB_ID}_err.txt"
mv "/groups/scienceai/tronkko/temp/logs/${SLURM_JOB_ID}_out.txt" "${outfolder}/${BASENAME}/prediction_${SLURM_JOB_ID}_out.txt"
