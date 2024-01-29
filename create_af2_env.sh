#!/bin/bash

# Install tmux and vim
apt-get update
apt-get install -y tmux vim

# Export cuda environment variables
export CUDA_HOME=/usr/local/cuda
export PATH=/usr/local/cuda/bin/${PATH:+:${PATH}}$
export CPATH=/usr/local/cuda/include:$CPATH
export LIBRARY_PATH=/usr/local/cuda/lib64:$LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64/${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}$

cd /workspace

# Clone github repo containing modified scripts for runpod.io
git clone https://github.com/teemuronkko/alphafold-runpod.git
cd ./alphafold-runpod
git checkout v2.3.1_runpod

# Make folder for AF model parameters
AFDB_DIR="/workspace/alphafold-genetic-databases/"
AF_DIR=$(pwd)
mkdir -p $AFDB_DIR

# Install aria2c and load model parameters
apt-get update
apt-get install -y aria2

# Download alphafold parameters if they are not present already
wget https://storage.googleapis.com/alphafold/alphafold_params_2022-01-19.tar
wget https://storage.googleapis.com/alphafold/alphafold_params_2022-03-02.tar
tar -xvf alphafold_params_2022-01-19.tar
tar -xvf alphafold_params_2022-03-02.tar
rm alphafold_params_2022-01-19.tar
rm alphafold_params_2022-03-02.tar

# Install Miniconda package manager.
wget -q -P /tmp \
  https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash /tmp/Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda \
    && rm /tmp/Miniconda3-latest-Linux-x86_64.sh

# Install conda packages.
export PATH="/opt/conda/bin:$PATH"

conda init
source ~/.bashrc 

conda create -n af2_runpod python=3.8 -y
conda activate af2_runpod
source activate af2_runpod

# Check if the current Conda environment matches the target environment
if [ "$CONDA_DEFAULT_ENV" == "af2_runpod" ]; then
  echo "af2_runpod conda environment activated."
else
  echo "af2_runpod conda environment was not activated. Exiting the script..."
  exit
fi

conda install -y -c conda-forge \
    openmm=7.5.1 \
    pdbfixer \
    pip

conda install -y -c bioconda hmmer hhsuite==3.3.0 kalign2

if [ ! -e ${AF_DIR}/alphafold/common/stereo_chemical_props.txt ]; then
  wget -q -P ${AF_DIR}/alphafold/common/ \
    https://git.scicore.unibas.ch/schwede/openstructure/-/raw/7102c63615b64735c4941278d92b554ec94415f8/modules/mol/alg/src/stereo_chemical_props.txt
fi

pip3 install --upgrade pip --no-cache-dir \
    && pip3 install -r ${AF_DIR}/requirements.txt --no-cache-dir \
    && pip3 install --upgrade --no-cache-dir \
      jax==0.3.25 \
      jaxlib==0.3.25+cuda11.cudnn805 \
      -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html

# Apply OpenMM patch.
cd /opt/conda/envs/af2_runpod/lib/python3.8/site-packages/
patch -p0 < ${AF_DIR}/docker/openmm.patch

# Go back to AF DIR
cd $AF_DIR

# Add SETUID bit to the ldconfig binary so that non-root users can run it.
chmod u+s /sbin/ldconfig.real


