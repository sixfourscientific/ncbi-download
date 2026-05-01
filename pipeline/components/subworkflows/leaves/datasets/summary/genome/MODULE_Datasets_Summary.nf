
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

            def outExt = Arguments.containsKey('--as-json-lines') && Arguments['--as-json-lines'] == true
                ? 'jsonl'
                : 'json'

            def outFile = "${CoreMeta.ID}.$outExt"

            return outFile }


    // TAKE & EMIT

    input:

        tuple   val  (CoreMeta),
                val  (Id),
                path (OPTIONAL),
                val  (Arguments)

    output:

        tuple   val  (CoreMeta),
                path ('*.{json,jsonl}'),

                emit: Main

    // MAIN

    script:

        """

        datasets summary genome \\
            $task.ext.arguments \\
            $CoreMeta.type "$Id" \\
            > $task.ext.outFile

        """

    }

/* 

VERSION: 18.23.0

Print a data report containing genome metadata. The data report is returned in JSON format.

Usage
  datasets summary genome [flags]
  datasets summary genome [command]

Sample Commands
  datasets summary genome accession GCF_000001405.40
  datasets summary genome taxon "mus musculus"
  datasets summary genome taxon human --assembly-level chromosome,complete
  datasets summary genome taxon "mus musculus" --search C57BL/6J --search "Broad Institute"

Available Commands
  accession   Print a data report containing assembled genome metadata by Assembly or BioProject accession
  taxon       Print a data report containing genome metadata by taxon (NCBI Taxonomy ID, scientific or common name at any tax rank)

Flags
      --annotated                 Limit to annotated genomes
      --as-json-lines             Output results in JSON Lines format
      --assembly-level string     Limit to genomes at one or more assembly levels (comma-separated):
                                    * chromosome
                                    * complete
                                    * contig
                                    * scaffold
                                     (default "[]")
      --assembly-source string    Limit to 'RefSeq' (GCF_) or 'GenBank' (GCA_) genomes (default "all")
      --assembly-version string   Limit to 'latest' assembly accession version or include 'all' (latest + previous versions)
      --exclude-atypical          Exclude atypical assemblies
      --exclude-multi-isolate     Exclude assemblies from multi-isolate projects
      --from-type                 Only return records with type material
      --limit string              Limit the number of genome summaries returned
                                    * all:      returns all matching genome summaries
                                    * a number: returns the specified number of matching genome summaries
                                       (default "all")
      --mag string                Limit to metagenome assembled genomes (only) or remove them from the results (exclude) (default "all")
      --reference                 Limit to reference genomes
      --released-after string     Limit to genomes released on or after a specified date (free format, ISO 8601 YYYY-MM-DD recommended)
      --released-before string    Limit to genomes released on or before a specified date (free format, ISO 8601 YYYY-MM-DD recommended)
      --report string             Choose the output type:
                                    * genome:   Retrieve the primary genome report
                                    * sequence: Retrieve the sequence report
                                    * ids_only: Retrieve only the genome identifiers
                                     (default "genome")
      --search strings            Limit results to genomes with specified text in the searchable fields:
                                  species and infraspecies, assembly name and submitter.
                                  To search multiple strings, use the flag multiple times.


Global Flags
      --api-key string   Specify an NCBI API key
      --debug            Emit debugging info
      --help             Print detailed help about a datasets command
      --version          Print version of datasets

Use datasets summary genome <command> --help for detailed help about a command.

*/
