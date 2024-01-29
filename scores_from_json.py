#!/usr/bin/env python

import os
import json
import pathlib
import sys
import glob
import tqdm

fasta=sys.argv[1]
output_dir_base=sys.argv[2]

fasta_name = pathlib.Path(fasta).stem
output_jsons = os.path.join(output_dir_base, fasta_name,'result*.pkl.json')
scores={}
for json_file in tqdm.tqdm(glob.glob(output_jsons)):
    with open(json_file,'rb') as f:
        d=json.load(f)
        model=json_file.replace('result','unrelaxed').replace('.pkl.json','.pdb')
        try:
            scores[model]=float(d['ranking_confidence'])
        except:
            print(f'ranking_confidence not found in {json_file}')

for model,score in sorted(scores.items(),key=lambda x:x[1],reverse=True):
    pkl=model.replace('unrelaxed','result').replace('.pdb','.pkl')
    print(model,pkl,score)
