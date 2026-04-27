```
   nextflow \
      -C /path/to/ncbi-download/pipeline/nextflow.config \
      run /path/to/ncbi-download/pipeline/stem.nf \
      -profile <profile> \
      -params-file /path/to/ncbi-download/pipeline/params/parameters.json \
      --samples /path/to/inputs.tsv \
      --execute [search|fetch|all] \
      --supplementary /path/to/files.tsv=TAXONOMY"
```

