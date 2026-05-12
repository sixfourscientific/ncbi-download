# README

A workflow to handle bulk downloads of assemblies & taxonomy files from NCBI

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


## Commands

```--execute```

```Query```: Obtain assembly summary information from ncbi

```Fetch```: Query & download individual assemblies from ncbi

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


## Configuration

Each process can be configured via the ```params-file``` by supplying information in the relevant nested object for a corresponding ```SOFTWARE``` ```COMMAND``` module on a particular workflow ```BRANCH```.

```
"SOFTWARE": {
	"COMMAND": {
		"BRANCH": {
			"CONFIG": {
          		"VERSION": [],
				"LABEL": {
					"INCLUDE"  : true,
					"SOFTWARE" : null,
					"PRE"      : null,
					"POST"     : null,
					"ALIASES"  : {}
					},
          		"ARGS": {
            		"CORE"  : {},
            		"SWEEP" : "/path/to/SweepInfo.tsv"
          			}
				}
			}
		}
	}
```


### Arguments

Arguments can be provided via the ```ARGS``` block where ```CORE``` arguments are applied to all instances & ```SWEEP``` arguments create seperate instances for each list of arguments. Flags & arguments should be provided as strings just as they would have been for the actual command including any preciding dashes whilst switches (i.e. flags without parameters) can be supplied/removed using using the appropriate boolean parameter e.g.

```
"ARGS": {
	"CORE"  :  { "--flagA : "parameterX" },
	"SWEEP" :[ 
		{ "--flagB : "parameterY", "--flagC" : true  }, 
		{ "--flagB : "parameterZ", "--flagC" : false }
		]
	}
```

The above would run the process twice for a single input e.g. 

Instance 1 

```
SOFTWARE COMMAND --flagA parameterX --flagB paremeterY --flagC INPUT1
```

Instance 2

```
SOFTWARE COMMAND --flagA parameterX --flagB paremeterZ INPUT1
```

If the same argument is provided to both argument blocks then the ```SWEEP``` argument takes priority. ```SWEEP``` arguments can also be provided as a tab delimited list e.g.

```
---flagB	--flagC
parameterY	true
parameterZ	false
```
