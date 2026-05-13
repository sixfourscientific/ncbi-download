# README

## Description

A nextflow workflow to assist with the bulk downloading of assemblies & taxonomy files from NCBI

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


## Workflow Command Line Argments

`--execute`

`query`: obtain assembly summary information from ncbi

`fetch`: execute Query & then download individual assemblies from ncbi

`--inputs`

Inputs can be either a list of taxon ids, taxon names or assembly accession codes with the header `taxon` or `accession` as appropriate.

e.g.

*taxon_ids.tsv*

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

*taxon_names.tsv*

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

*accessions.tsv*

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

`--supplementary`

An optional list of urls with the header 'url' for the taxonomy files to be downloaded.

e.g.

*file_urls.tsv*

```
url
https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
https://ftp.ncbi.nlm.nih.gov/blast/db/taxdb-metadata.json
https://ftp.ncbi.nlm.nih.gov/blast/db/taxdb.tar.gz
```


## Workflow Configuration

Individual processes can be configured via the `params-file` by supplying information within the `CONFIG` block of the nested object for the corresponding `SOFTWARE` `COMMAND` module on a particular workflow `BRANCH`.

*params-file.json*

```
"SOFTWARE": {
   "COMMAND": {
      "BRANCH": {
         "CONFIG": {
            "VERSION" : [],
            "LABEL"   : {},
            "ARGS"    : {}
            }
         }
      }
   }
```

See the `defaults.json` file for a basic configuration.



### Process Command Line Arguments

Processes that accept command line arguments can have these configured via the `ARGS` block where `CORE` arguments are applied to all instances whilst the list of `SWEEP` argument submaps create seperate instances for the cartesian products of individual argument submaps & each input. If the same argument is provided in both options then that within the `SWEEP` option takes priority. 

Flags & parameters should be provided as strings just as they would have been were the particular software used for a process to be run via the command line (i.e. including any preceding dashes) whilst switches (i.e. flags without parameters) can be either supplied or removed by providing the appropriate boolean parameter.

e.g.

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
SOFTWARE COMMAND --flagA parameterX --flagB parameterY --flagC INPUT1
```

#### Instance 2

```
SOFTWARE COMMAND --flagA parameterX --flagB parameterZ INPUT1
```

It is also possible to provide `SWEEP` arguments as a tab delimited list by providing a path to this file in place of the submap list.

e.g.

*SweepInfo.tsv*

```
--flagB	--flagC
parameterY	true
parameterZ	false
```

*params-file.json*

```
"ARGS": {
   "CORE"  : { "--flagA" : "parameterX" },
   "SWEEP" : "/path/to/SweepInfo.tsv"
   }
```

In this workflow arguments are configurable for the following processes blocks:

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



### Process Software Version

If configured, processes can be executed for multiple software versions by providing a list of release tags to the `VERSION` option. Seperate instances are created for the cartesian products of individual software versions & each parameter sweep (see above). For example, if two argument submaps are provided along with two release tags to the `SWEEP` & `VERSION` options respectively, then a total of four instances are created per input with every parameter sweep processed using each of the software versions. If not provided then the process would typically default to a specified software version within the configuration.



### Process Metadata Label

For each process, metadata associated with the state or processing can be recorded for an input via the `LABEL` block. This s particularly useful when performing parameter sweeps since it records information about the command line arguments provided. 

*params-file.json*

```
"LABEL": {
   "INCLUDE" : <bool>,
   "MODULE"  : <string>,
   "PRE"     : <string>,
   "POST"    : <string>,
   "ALIASES" : {}
   }
```

The `INCLUDE` option toggles whether any metadata tags are recorded for a process by providing the apporprioate boolean parameter. Otherwise, a `MODULE` tag can describe what processing is taking place whilst the `PRE` & `POST` tags can describe the pre-process or post-process state of an input (i.e. the state immediately prior to or immediatley following the current process) respectivley. 

The `ALIASES` option takes a map where the keys are the command line flags/parameters provided via the `ARGS` block & the values are corresponding aliases to be recorded within the metadata tag. This can be useful when particular flags/parameters are long & a shorter alias is preferable.

e.g.

*params-file.json*

```
"LABEL": {
   "ALIASES" :[
      "--flagA"    : "fA",
      "--flagB"    : "fB",
      "--flagC"    : "fC",
      "parameterX" : "pX",
      "parameterY" : "pY",
      "parameterZ" : "pZ",
      (true)       : "T",
      (false)      : "F"
      } 
   }
```

In the example used earlier the process would label each input with the following tags:

#### Without Aliases

```
INSTANCE1 TAG: "flagAparameterX.flagBparameterY.flagCTrue"
INSTANCE2 TAG: "flagAparameterX.flagBparameterZ.flagCFalse"
```

#### With Aliases

```
INSTANCE1 TAG: "fApX.fBpY.fCT"
INSTANCE2 TAG: "fApX.fBpZ.fCF"
```

If no command line arguments are provided a tag of `DEFAULT` is included which itelf can be substituted with an alias. Several default aliases are hard coded (see below) but those within the `ALIASES` option take priority.

#### Default Aliases

```
"DEFAULT" : "def"
(null)    : "NA"
(true)    : "T"
(false)   : "F"
```