# AFsample - AlphaFold with aggressive sampling

This package provides an implementation of the `Wallner` method that was the best 
method in multimer prediction in CASP15.

It is based on the AlphaFold system developed by DeepMind
https://github.com/deepmind/alphafold/


## Setup

The setup is identical to regular AlphaFold. If have already setup of AlphaFold you only need to change the `data_dir` in `run_alphafold.py` to point to the location of `$DOWNLOAD_DIR` containing all the databases and model parameters.

If you are setting up AlphaFold for the first time (a shorter version adapted from: https://github.com/deepmind/alphafold/):

1.  Download genetic databases (see below).
1.  Download model parameters, make sure you download multimer_v1 and mulitmer_v2 (see below).
1.  Create a conda environment `conda env create -f afsample.yml` <!--jaxlib==0.1.69+cuda111 removed-->'
    
    If you don't have conda, install Anaconda before continuing, instructions here: https://www.anaconda.com/
    
    Activate the environment `conda activate afsample` and install `jaxlib >= 0.1.69` that is compatibile with the CUDA version installed in your system, instructions here: https://github.com/google/jax#pip-installation-gpu-cuda

### Genetic databases

This step requires `aria2c` to be installed on your machine.

AlphaFold needs multiple genetic (sequence) databases to run:

*   [BFD](https://bfd.mmseqs.com/),
*   [MGnify](https://www.ebi.ac.uk/metagenomics/),
*   [PDB70](http://wwwuser.gwdg.de/~compbiol/data/hhsuite/databases/hhsuite_dbs/),
*   [PDB](https://www.rcsb.org/) (structures in the mmCIF format),
*   [PDB seqres](https://www.rcsb.org/) – only for AlphaFold-Multimer,
*   [Uniclust30](https://uniclust.mmseqs.com/),
*   [UniProt](https://www.uniprot.org/uniprot/) – only for AlphaFold-Multimer,
*   [UniRef90](https://www.uniprot.org/help/uniref).

The script `scripts/download_all_data.sh` that can be used to download
and set up all of these databases:

*   Default:

    ```bash
    scripts/download_all_data.sh <DOWNLOAD_DIR>
    ```

    will download the full databases.

*   With `reduced_dbs`:

    ```bash
    scripts/download_all_data.sh <DOWNLOAD_DIR> reduced_dbs
    ```

    will download a reduced version of the databases to be used with the
    `reduced_dbs` database preset.


:ledger: **Note: The total download size for the full databases is around 415 GB
and the total size when unzipped is 2.2 TB. Please make sure you have a large
enough hard drive space, bandwidth and time to download. We recommend using an
SSD for better genetic search performance.**

The `download_all_data.sh` script will also download the model parameter files.
Once the script has finished, you should have the following directory structure:

```
$DOWNLOAD_DIR/                             # Total: ~ 2.2 TB (download: 438 GB)
    bfd/                                   # ~ 1.7 TB (download: 271.6 GB)
        # 6 files.
    mgnify/                                # ~ 64 GB (download: 32.9 GB)
        mgy_clusters_2018_12.fa
    params/                                # ~ 3.5 GB (download: 3.5 GB)
        # 5 CASP14 models,
        # 5 pTM models,
        # 5 AlphaFold-Multimer models,
        # LICENSE,
        # = 16 files.
    pdb70/                                 # ~ 56 GB (download: 19.5 GB)
        # 9 files.
    pdb_mmcif/                             # ~ 206 GB (download: 46 GB)
        mmcif_files/
            # About 180,000 .cif files.
        obsolete.dat
    pdb_seqres/                            # ~ 0.2 GB (download: 0.2 GB)
        pdb_seqres.txt
    small_bfd/                             # ~ 17 GB (download: 9.6 GB)
        bfd-first_non_consensus_sequences.fasta
    uniclust30/                            # ~ 86 GB (download: 24.9 GB)
        uniclust30_2018_08/
            # 13 files.
    uniprot/                               # ~ 98.3 GB (download: 49 GB)
        uniprot.fasta
    uniref90/                              # ~ 58 GB (download: 29.7 GB)
        uniref90.fasta
```

`bfd/` is only downloaded if you download the full databases, and `small_bfd/`
is only downloaded if you download the reduced databases.

### Model parameters
The method is using both v2.1.0 and v2.2.0 AlphaFold-Multimer model weights. Download them using the links below and extract them in the `params/` folder in the `$DOWNLOAD_DIR`.

The v2.2.0 AlphaFold-Multimer model weights:
https://storage.googleapis.com/alphafold/alphafold_params_2022-03-02.tar
The v2.1.0 AlphaFold-Multimer model weights:
https://storage.googleapis.com/alphafold/alphafold_params_2022-01-19.tar


1.  You can control which AlphaFold model to run by adding the
    `--model_preset=` flag. 
    
    * **multimer\_v1**: will run mulitmer_v1
    
    * **multimer\_v2**: will run mulitmer_v2 
    
    * **multimer\_all**: will run mulitmer_v1 and mulitmer_v2 

    * **multimer**: will default to mulitmer_v2 
    
    The monomer flags also works but are not used by the multimer method:
    
    * **monomer**: The original model

    * **monomer\_ptm**: Model with the pTM head, providing a pairwise confidence measure. 
   
    * **monomer_all**: Both original and pTM 
      

1.  You can control MSA speed/quality tradeoff by adding
    `--db_preset=reduced_dbs` or `--db_preset=full_dbs` to the run command. We
    provide the following presets:

    *   **reduced\_dbs**: This preset is optimized for speed and lower hardware
        requirements. It runs with a reduced version of the BFD database.
        It requires 8 CPU cores (vCPUs), 8 GB of RAM, and 600 GB of disk space.

    *   **full\_dbs**: This runs with all genetic databases used at CASP14.

    The method is using the `full_dbs` setting.
    
   

### Running AlphaFold-Multimer

All steps are the same as when running the monomer system, but you will have to

*   provide an input fasta with multiple sequences,
*   set `--model_preset=multimer`,

An example that folds a protein complex `multimer.fasta`:

```bash
python3 run_alphafold.py \
  --fasta_paths=multimer.fasta \
  --max_template_date=2020-05-14 \
  --model_preset=multimer \
  --data_dir=$DOWNLOAD_DIR
```

By default the multimer system will run 5 seeds per model (25 total predictions)
for a small drop in accuracy you may wish to run a single seed per model.  This
can be done via the `--num_multimer_predictions_per_model` flag, e.g. set it to
`--num_multimer_predictions_per_model=1` to run a single seed per model.

### Examples

Below are examples on how to use AlphaFold in different scenarios.

#### Folding a monomer

Say we have a monomer with the sequence `<SEQUENCE>`. The input fasta should be:

```fasta
>sequence_name
<SEQUENCE>
```

Then run the following command:

```bash
python3 docker/run_docker.py \
  --fasta_paths=monomer.fasta \
  --max_template_date=2021-11-01 \
  --model_preset=monomer \
  --data_dir=$DOWNLOAD_DIR
```

#### Folding a homomer

Say we have a homomer with 3 copies of the same sequence
`<SEQUENCE>`. The input fasta should be:

```fasta
>sequence_1
<SEQUENCE>
>sequence_2
<SEQUENCE>
>sequence_3
<SEQUENCE>
```

Then run the following command:

```bash
python3 docker/run_docker.py \
  --fasta_paths=homomer.fasta \
  --max_template_date=2021-11-01 \
  --model_preset=multimer \
  --data_dir=$DOWNLOAD_DIR
```

#### Folding a heteromer

Say we have an A2B3 heteromer, i.e. with 2 copies of
`<SEQUENCE A>` and 3 copies of `<SEQUENCE B>`. The input fasta should be:

```fasta
>sequence_1
<SEQUENCE A>
>sequence_2
<SEQUENCE A>
>sequence_3
<SEQUENCE B>
>sequence_4
<SEQUENCE B>
>sequence_5
<SEQUENCE B>
```

Then run the following command:

```bash
python3 docker/run_docker.py \
  --fasta_paths=heteromer.fasta \
  --max_template_date=2021-11-01 \
  --model_preset=multimer \
  --data_dir=$DOWNLOAD_DIR
```


#### Folding multiple multimers one after another

Say we have a two multimers, `multimer1.fasta` and `multimer2.fasta`.

We can fold both sequentially by using the following command:

```bash
python3 docker/run_docker.py \
  --fasta_paths=multimer1.fasta,multimer2.fasta \
  --max_template_date=2021-11-01 \
  --model_preset=multimer \
  --data_dir=$DOWNLOAD_DIR
```

### output

The outputs will be saved in a subdirectory of the directory provided via the
`--output_dir`. The outputs compared to regular AlphaFold have been scaled down
to allow massive sampling it includes the computed MSAs, unrelaxed structures, and 
selective model outputs. Relaxing the structures is default turned off to save time
and instead the script `run_relax_from_results_pkl.py` is provided to allow relaxing
selected structures using the result pickled 

, relaxed structures,
ranked structures, raw model outputs, prediction metadata, and section timings.
The `--output_dir` directory will have the following structure:

```
<target_name>/
    features.pkl
    ranked_{0:N}.pdb # legacy included
    ranking_debug.json
    result_model_{1:N}.pkl
    timings.json
    unrelaxed_model_{1:N}.pdb
    msas/
        bfd_uniclust_hits.a3m
        mgnify_hits.sto
        uniref90_hits.sto
```

The contents of each output file are as follows:

*   `features.pkl` – A `pickle` file containing the input feature NumPy arrays
    used by the models to produce the structures.
*   `unrelaxed_model_*.pdb` – A PDB format text file containing the predicted
    structure, exactly as outputted by the model.
*   [MODIFIED, relax is default off] `relaxed_model_*.pdb` – A PDB format text file containing the predicted
    structure, after performing an Amber relaxation procedure on the unrelaxed
    structure prediction (see Jumper et al. 2021, Suppl. Methods 1.8.6 for
    details).
*   [MODIFIED, legacy kept are unrelaxed default] `ranked_*.pdb` – A PDB format text file containing the relaxed predicted
    structures, after reordering by model confidence. Here `ranked_0.pdb` should
    contain the prediction with the highest confidence, and `ranked_4.pdb` the
    prediction with the lowest confidence. To rank model confidence, we use
    predicted LDDT (pLDDT) scores (see Jumper et al. 2021, Suppl. Methods 1.9.6
    for details).
*   `ranking_debug.json` – A JSON format text file containing the pLDDT values
    used to perform the model ranking, and a mapping back to the original model
    names.
*   `timings.json` – A JSON format text file containing the times taken to run
    each section of the AlphaFold pipeline.
*   `msas/` - A directory containing the files describing the various genetic
    tool hits that were used to construct the input MSA.
*   [NEW] `result_model_*.pkl.json` – A JSON format text file with the scores `pTM`, 
    `ipTM`, and `ranking_confidence` to enable fast retrieval without the need to 
    read the relatively large `result_model_*.pkl` file. [NEW]
*   [MODIFIED] `result_model_*.pkl` – A `pickle` file containing a nested dictionary of the
    various NumPy arrays directly produced by the model. From the original produced
    by AlphaFold the following data structures are removed: `experimentally_resolved`, 
    `masked_msa`, `aligned_confidence_probs` to save space (unless you run with the
    `--output_all_results` flag). The dictionary contains the following: 

    *   Distograms (`distogram/logits` contains a NumPy array of shape [N_res,
        N_res, N_bins] and `distogram/bin_edges` contains the definition of the
        bins).
    *   Per-residue pLDDT scores (`plddt` contains a NumPy array of shape
        [N_res] with the range of possible values from `0` to `100`, where `100`
        means most confident). This can serve to identify sequence regions
        predicted with high confidence or as an overall per-target confidence
        score when averaged across residues.
    *   Present only if using pTM models: predicted TM-score (`ptm` field
        contains a scalar). As a predictor of a global superposition metric,
        this score is designed to also assess whether the model is confident in
        the overall domain packing.
    *   Present only if using pTM models: predicted pairwise aligned errors
        (`predicted_aligned_error` contains a NumPy array of shape [N_res,
        N_res] with the range of possible values from `0` to
        `max_predicted_aligned_error`, where `0` means most confident). This can
        serve for a visualisation of domain packing confidence within the
        structure.

The pLDDT confidence measure is stored in the B-factor field of the output PDB
files (although unlike a B-factor, higher pLDDT is better, so care must be taken
when using for tasks such as molecular replacement).


#
