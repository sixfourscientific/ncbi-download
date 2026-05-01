
include { 
    formatArguments as formatArguments;
    makeTag as makeTag;
    } from "$params.importMap.functions/core/Utils"

process MODULE {

    // SETUP

    tag "$task.ext.tag"

    label workflow.profile in params.profileLabels 
        ? workflow.profile.toUpperCase()
        : 'DEFAULT'

    // EXTRA
    
    ext tag : {
    
        def tag = makeTag(
            tags      : [ CoreMeta.ID, CoreMeta.TAG ],
            delimiter :'-',
            )
    
        return tag },

    version : {

            def version = CoreMeta.STAGING.VERSION

            return version },

        arguments: { 

            def arguments = formatArguments( Arguments, '\s', '            ')

            return arguments },

        outFile: { 

            def outFile = "OUTPUT.EXT"

            return outFile }


    // TAKE & EMIT

    input:

        tuple   val  (CoreMeta),
                path (INPUT),
                path (OPTIONAL),
                val  (Arguments)

    output:

        tuple   val  (CoreMeta),
                path ('**/*.zip'),

                emit: Main

    // MAIN

    script:

        """

        while IFS=\$'\\t' read -r ID ACCESSION; do

            echo -e "\\nProcessing \$ACCESSION (\$ID)"

            # specify archive directory
            ZIPDIR="\${ID// /_}/\${ACCESSION}"
            mkdir -p \$ZIPDIR

            ZIPFILE="\${ZIPDIR}/\${ACCESSION}.zip"

            # attempt resubmit before fail
            success=false
            attempt_max=3
            attempt_num=0

            while [ \$success = false ] && [ \$attempt_num -le \$attempt_max ]; do

                attempt_num=\$(( attempt_num + 1 ))
                
                case \$attempt_num in

                1) echo -e "\\nFetching..." ;;

                *) echo -e "\\nRetrying (attempt \$attempt_num)..." ;;

                esac

                # download assembly zip archive
                set +e
                datasets download genome \\
                    $task.ext.arguments \\
                    --filename \${ZIPFILE} \\
                    accession \${ACCESSION}
                EXITCODE1="\$?"
                set -e

                # test archive integrity
                if [ -f \$ZIPFILE ] && [ \$EXITCODE1 -eq 0 ]; then

                    set +e
                    unzip -t \${ZIPFILE}
                    EXITCODE2="\$?"
                    set -e

                    case \$EXITCODE2 in

                    0) 
                        echo -e "Done.\\n"

                        success=true ;;

                    *) 
                        echo -e "\\nERROR ~ Testing archive failed; \$ACCESSION (\$ID)"

                        rm \$ZIPFILE ;;

                    esac

                fi

                if [ \$success = false ]; then

                    echo -e "\\nERROR ~ Download failed (Attempt \$attempt_num of \$attempt_max); \$ACCESSION (\$ID)" 

                    case \$attempt_num in

                    \$attempt_max) 

                        echo -e "\\nINFO ~ Download attempts exceeded; \$ACCESSION (\$ID)\\n"
                        
                        exit 1 ;;

                    *) sleep 2 ;;

                    esac
                fi

                done

        done < $INPUT

        """

    }

/* 

VERSION: 18.23.0

Download a genome data package. Genome data packages may include genome, transcript and protein sequences, annotation and one or more data reports. Data packages are downloaded as a zip archive.

The default genome data package includes the following files:
  * <accession>_<assembly_name>_genomic.fna (genomic sequences)
  * assembly_data_report.jsonl (data report with genome assembly and annotation metadata)
  * dataset_catalog.json (a list of files and file types included in the data package)

Usage
  datasets download genome [flags]
  datasets download genome [command]

Sample Commands
  datasets download genome accession GCF_000001405.40 --chromosomes X,Y --include genome,gff3,rna
  datasets download genome taxon "bos taurus" --dehydrated
  datasets download genome taxon human --assembly-level chromosome,complete --dehydrated
  datasets download genome taxon "house mouse" --search C57BL/6J --search "Broad Institute" --dehydrated

Available Commands
  accession   Download a genome data package by Assembly or BioProject accession
  taxon       Download a genome data package by taxon (NCBI Taxonomy ID, scientific or common name at any tax rank)

Flags
      --annotated                 Limit to annotated genomes
      --assembly-level string     Limit to genomes at one or more assembly levels (comma-separated):
                                    * chromosome
                                    * complete
                                    * contig
                                    * scaffold
                                     (default "[]")
      --assembly-source string    Limit to 'RefSeq' (GCF_) or 'GenBank' (GCA_) genomes (default "all")
      --assembly-version string   Limit to 'latest' assembly accession version or include 'all' (latest + previous versions)
      --chromosomes strings       Limit to a specified, comma-delimited list of chromosomes, or 'all' for all chromosomes
      --dehydrated                Download a dehydrated zip archive including the data report and locations of data files (use the rehydrate command to retrieve data files).
      --exclude-atypical          Exclude atypical assemblies
      --exclude-multi-isolate     Exclude assemblies from multi-isolate projects
      --fast-zip-validation       Skip zip checksum validation after download
      --from-type                 Only return records with type material
      --include string(,string)   Specify the data files to include (comma-separated).
                                    * genome:     genomic sequence
                                    * rna:        transcript
                                    * protein:    amino acid sequences
                                    * cds:        nucleotide coding sequences
                                    * gff3:       general feature file
                                    * gtf:        gene transfer format
                                    * gbff:       GenBank flat file
                                    * seq-report: sequence report file
                                    * all:        include all available file types (equivalent to genome,protein,cds,gff3,gtf,gbff,rna,seq-report)
                                    * none:       do not retrieve any sequence files
                                     (default [genome])
      --mag string                Limit to metagenome assembled genomes (only) or remove them from the results (exclude) (default "all")
      --preview                   Show information about the requested data package
      --reference                 Limit to reference genomes
      --released-after string     Limit to genomes released on or after a specified date (free format, ISO 8601 YYYY-MM-DD recommended)
      --released-before string    Limit to genomes released on or before a specified date (free format, ISO 8601 YYYY-MM-DD recommended)
      --search strings            Limit results to genomes with specified text in the searchable fields:
                                  species and infraspecies, assembly name and submitter.
                                  To search multiple strings, use the flag multiple times.


Global Flags
      --api-key string    Specify an NCBI API key
      --debug             Emit debugging info
      --filename string   Specify a custom file name for the downloaded data package (default "ncbi_dataset.zip")
      --help              Print detailed help about a datasets command
      --no-progressbar    Hide progress bar
      --version           Print version of datasets

Use datasets download genome <command> --help for detailed help about a command.

*/
