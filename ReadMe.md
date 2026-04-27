```
   nextflow \
      -C /path/to/ncbi-download/pipeline/nextflow.config \
      run /path/to/ncbi-download/pipeline/stem.nf \
      -profile <profile> \
      -params-file /path/to/ncbi-download/pipeline/params/parameters.json \
      --execute [search|fetch] \
      --inputs /path/to/inputs.tsv \
      --supplementary /path/to/files.tsv=TAXONOMY"
```

Inputs

Inputs can be either a list of taxids, binomial names or assembly accession codes just make sure that the header is either 'taxon' for ids & names or 'accession' for codes.

e.g.
```
taxon
287
562
28901
1613
1351
1280
1639
1423
```

```
taxon
Pseudomonas aeruginosa
Escherichia coli
Salmonella enterica
Limosilactobacillus fermentum
Enterococcus faecalis
Staphylococcus aureus
Listeria monocytogenes
Bacillus subtilis
```

```
accession

```