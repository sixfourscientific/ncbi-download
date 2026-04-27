# README



## Quickstart
```
   nextflow \
      -C /path/to/ncbi-download/pipeline/nextflow.config \
      run /path/to/ncbi-download/pipeline/stem.nf \
      -profile <profile> \
      -params-file /path/to/ncbi-download/pipeline/params/parameters.json \
      --execute [query|fetch] \
      --inputs /path/to/ids.tsv \
      --supplementary "/path/to/urls.tsv=TAXONOMY"
```


## Arguments

```--execute```

```Query```: Obtain assembly summary information from ncbi

```Fetch```: Search & download individual assemblies from ncbi

```--inputs```

Inputs can be either a list of taxon ids, taxon names or assembly accession codes with the header 'taxon' or 'accession' as appropriate.

e.g.

*Taxon ids*

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

*Taxon names*

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

*Accessions*

```
accession
GCF_000006765.1
GCF_000005845.2
GCF_000008865.2
GCF_000006945.2
GCF_005341425.1
GCF_000393015.1
GCF_000013425.1
GCF_000196035.1
GCF_000009045.1

```

```--supplementary```

An optional list of urls with the header 'url' for the taxonomy files to be downloaded.

e.g.

```
url
https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
https://ftp.ncbi.nlm.nih.gov/blast/db/taxdb-metadata.json
https://ftp.ncbi.nlm.nih.gov/blast/db/taxdb.tar.gz
```
