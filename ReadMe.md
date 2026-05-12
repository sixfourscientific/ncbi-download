# README

A workflow to handle bulk downloads of assemblies & taxonomy files from NCBI

## Quickstart
```
   nextflow \
      -C /path/to/ncbi-download/pipeline/nextflow.config \
      run /path/to/ncbi-download/pipeline/stem.nf \
      -profile <profile> \
      -params-file /path/to/ncbi-download/pipeline/params/params-file.json \
      --execute [query|fetch] \
      --inputs /path/to/ids.tsv \
      --supplementary "/path/to/urls.tsv=TAXONOMY"
```


## Workflow Command Argments

```--execute```

```Query```: obtain assembly summary information from ncbi

```Fetch```: execute Query & then download individual assemblies from ncbi

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


## Workflow Configuration

### Processes

Individual processes can be configured via the ```params-file``` by supplying information in the ```CONFIG``` block of the corresponding nested object for a ```SOFTWARE``` ```COMMAND``` module on a particular workflow ```BRANCH```.

*params-file.json*

```
"SOFTWARE": {
   "COMMAND": {
      "BRANCH": {
         "CONFIG": {
            "VERSION": [],
            "LABEL": {
               "INCLUDE" : true,
               "MODULE " : null,
               "PRE"     : null,
               "POST"    : null,
               "ALIASES" : {}
               },
            "ARGS": {
               "CORE"  : {},
               "SWEEP" : [{},{}]
               }
            }
         }
      }
   }
```

#### Command Line Arguments

Where appropriate, arguments can be provided for a proccess via the ```ARGS``` block where ```CORE``` arguments are applied to all instances whilst the list of ```SWEEP``` arguments create seperate instances for the cartesian products of the individual argument submaps & each input. If the same argument is provided to both blocks then that within the ```SWEEP``` block takes priority. 

Flags & parameters should be provided as strings just as they would have been were the process to be run via the command line (i.e. including any preceding dashes) whilst switches (i.e. flags without parameters) can be either supplied or removed respectively by providing the appropriate boolean parameter e.g.

*params-file.json*

```
"ARGS": {
   "CORE"  :  { "--flagA" : "parameterX" },
   "SWEEP" :[ 
      { "--flagB" : "parameterY", "--flagC" : true  }, 
      { "--flagB" : "parameterZ", "--flagC" : false }
      ]
   }
```

In the above example the process would run twice for a single input with the following command line arguments: 

#### Instance 1 

```
SOFTWARE COMMAND --flagA parameterX --flagB paremeterY --flagC INPUT1
```

#### Instance 2

```
SOFTWARE COMMAND --flagA parameterX --flagB paremeterZ INPUT1
```

It is also possible to provide```SWEEP``` arguments as a tab delimited list by providing a path to this file in place of the submap list e.g.

*SweepInfo.tsv*

```
---flagB	--flagC
parameterY	true
parameterZ	false
```

*params-file.json*

```
"ARGS": {
   "CORE"  : { "--flagA : "parameterX" },
   "SWEEP" : "/path/to/SweepInfo.tsv"
   }
```

Example arguments can be found within the ```defaults.json``` file. In this workflow the configurable module blocks are as follows:

```
"DATASETS": {
   "SUMMARY": {
      "QUERY": {
         "CONFIG": {},
         }
      },
   "DOWNLOAD": {
      "FETCH": {
         "CONFIG": {},
         }
      }
   }
```


