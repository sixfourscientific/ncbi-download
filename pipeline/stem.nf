#!/usr/bin/env nextflow

/* enable dsl syntax extension (should be applied by default) */
nextflow.enable.dsl = 2


// FUNCTIONS

params.PUBLISH = true

include { 
    parseSupplementary as parseSupplementary;
    viewMeta as viewMeta;
    prepBridge as prepBridge;
    parseUrl as parseUrl;
    makeTag as makeTag;
    } from "./components/functions/core/Utils"

// SUBWORKFLOWS

include { 
    Info_Parse as ParseInfo;
    } from "./components/subworkflows/core/Info_Parse"

include { 
    Dummy_Add as AddDummy;
    } from "./components/subworkflows/core/Dummy_Add"

include { 
    Subsets_Parse as ParseSubsets;
    } from "./components/subworkflows/core/Subsets_Parse"

include {
    SUBWORKFLOW as Query;
    } from "./components/subworkflows/branches/BRANCH_Query"

include {
    SUBWORKFLOW as Count;
    } from "./components/subworkflows/branches/BRANCH_Count"

include {
    SUBWORKFLOW as Format;
    } from "./components/subworkflows/branches/BRANCH_Format"

include {
    SUBWORKFLOW as Split;
    } from "./components/subworkflows/branches/BRANCH_Split"

include {
    SUBWORKFLOW as Examine;
    } from "./components/subworkflows/branches/BRANCH_Examine"

include {
    SUBWORKFLOW as Filter;
    } from "./components/subworkflows/branches/BRANCH_Filter"

include {
    SUBWORKFLOW as Collect;
    } from "./components/subworkflows/branches/BRANCH_Collect"

include {
    SUBWORKFLOW as Fetch;
    } from "./components/subworkflows/branches/BRANCH_Fetch"

include {
    SUBWORKFLOW as Divide;
    } from "./components/subworkflows/branches/BRANCH_Divide"

include {
    SUBWORKFLOW as Taxonomy;
    } from "./components/subworkflows/branches/BRANCH_Taxonomy"

////BRANCH_IMPORT////


workflow { 

    main:


        // SETUP

        taxonomySubdir = 'taxonomy'
        datasetsSubdir = 'datasets'

        parseSupplementary( params.supplementary, params )

        Parameters = params

        EXECUTE  = params.execute.split(',')

        RUN_QUERY = EXECUTE.contains('query')

        RUN_FETCH = EXECUTE.contains('fetch')

        ////BRANCH_FILTER////


        // MAIN

        println('PARSING INPUTS...')

        def InputMeta = (params.INPUT?.MAIN ?: [:]) + [
            INFO     : params.inputs,
            TYPE     : "TARGETS",
            DETAILED : true,
            ID_FIELD : ['taxon','accession'],
            ]

        Inputs = ParseInfo( InputMeta )

            | map { coreMeta ->

                def entryType = coreMeta.INFO.FIELDS[0]

                def coreMetaNew = [
                    ID    : coreMeta.ID,
                    entry : coreMeta[(entryType)],
                    type  : entryType,
                    ]

                return coreMetaNew }

        Inputs = AddDummy(Inputs, [ dummy : 'optional.dummy' ])

        // SUPPLEMENTARY

        def TaxonomyMeta = [
            INFO     : params.TAXONOMY,
            TYPE     : "TAXONOMY",
            ]

        TAXONOMY = ParseInfo( TaxonomyMeta ) 

            // remove empty map (when no taxonomy provided)
            | filter { coreMeta -> coreMeta }
        
            // create custom tag from parsed url
            | map { coreMeta ->

                def urlList = parseUrl(coreMeta['url'])

                def entryID = makeTag(
                    tags      : urlList,
                    delimiter : '-',
                    )

                def coreMetaNew = coreMeta + [
                    ID : entryID,
                    ]

                return coreMetaNew }


        // BRANCHES

        println('RUNNING BRANCHES...')
        
        // BRANCH( Inputs|BRANCH.out.Main)


        // QUERY

        // obtain datasets summary
        Query( Parameters, Inputs | filter { RUN_QUERY || RUN_FETCH }  )

        // examine report availability
        Count( Parameters, Query.out )

        // reformat json/jsonl as tsv
        Format( Parameters, Count.out | filter { coreMeta -> coreMeta.AVAILABLE } )

        // seperate individual reports
        Split( Parameters, Format.out )

        // examine accessions mapped to query IDs 
        Examine( Parameters, Split.out )

        // filter accessions according to criteria
        Filter( Parameters, Examine.out )


        // FETCH

        // collect accessions
        Collect( Parameters, Filter.out )

        // subset accesssions into batches
        ParseSubsets( Parameters, Collect.out )

        // download datasets
        Fetch( Parameters, ParseSubsets.out | filter { RUN_FETCH } )

        // divide datasets
        Divide( Parameters, Fetch.out )


        // TAXONOMY

        // obtain supplementary taxonomy files (if provided)
        Taxonomy( Parameters, TAXONOMY )

        ////BRANCH_RUN////


    /*
    */


    publish: 
    
        Format = Format.out.map{ coreMeta ->

            def indexMeta = [
                results : coreMeta.total,
                summary : coreMeta.OUTPUTS.DATASETS.SUMMARY.QUERY.main,
                table   : coreMeta.OUTPUTS.CUSTOM.TABULATE.FORMAT.main,
                ]
            
            def indexMetaNew = prepBridge( 
                coreMeta  : coreMeta, 
                indexMeta : indexMeta, 
                BASIC     : false, 
                UPDATE    : false, 
                INTERIM   : false,
                )

            return indexMetaNew }

        Examine = Examine.out.map{ coreMeta ->

            def indexMeta = [
                accession : coreMeta.report.accession,
                PRIORIRTY : coreMeta.PRIORITY,
                ]
            
            def indexMetaNew = prepBridge( 
                coreMeta  : coreMeta, 
                indexMeta : indexMeta, 
                BASIC     : false, 
                UPDATE    : false, 
                INTERIM   : false,
                )
            
            return indexMetaNew }

        Fetch = Divide.out.map{ coreMeta ->

            def indexMeta = [
                files : coreMeta.OUTPUTS.DATASETS.DOWNLOAD.FETCH.main,
                ]
            
            def indexMetaNew = prepBridge( 
                coreMeta  : coreMeta, 
                indexMeta : indexMeta, 
                BASIC     : false, 
                UPDATE    : false, 
                INTERIM   : false,
                )
            
            return indexMetaNew }

        Taxonomy = Taxonomy.out.map{ coreMeta ->

            def indexMeta = [
                files : coreMeta.OUTPUTS.CUSTOM.DOWNLOAD.TAXONOMY.main,
                ]
            
            def indexMetaNew = prepBridge( 
                coreMeta  : coreMeta, 
                indexMeta : indexMeta, 
                BASIC     : false, 
                UPDATE    : false, 
                INTERIM   : false,
                )
            
            return indexMetaNew }

        Main = Divide.out.unique{ coreMeta -> coreMeta.TAG }.map{ coreMeta ->

            // N.B. general bridge using first element

            def taxonomySubdir = params.TAXONOMY 
                ? "${workflow.outputDir}/$taxonomySubdir"
                : 'NA'
            
            def indexMeta = [
                ID       : 'datasets',
                TAG      : coreMeta.TAG,
                datasets : "${workflow.outputDir}/$datasetsSubdir/$coreMeta.TAG",
                taxonomy : taxonomySubdir,
                ]
            
            def indexMetaNew = prepBridge( 
                coreMeta  : coreMeta, 
                indexMeta : indexMeta, 
                BASIC     : true, 
                UPDATE    : false, 
                INTERIM   : false,
                )
            
            return indexMetaNew }

        ////BRANCH_PUBLISH////

    }


output {

        Format { 
            enabled      true
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            path { indexMeta -> 
                return "query/$indexMeta.run" }
            index {
                path   'bridge-query-summaries.csv'
                header true
                sep    '\t'
                }
            }

        Examine { 
            enabled      true
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            path { indexMeta -> 
                return "query/$indexMeta.run/split" }
            index {
                path   'bridge-query-accessions.csv'
                header true
                sep    '\t'
                }
            }

        Fetch { 
            enabled      true
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            path { indexMeta -> 
                indexMeta.files >> "$datasetsSubdir/$indexMeta.TAG/" 
                }
            index {
                path   'bridge-fetch-datasets.csv'
                header true
                sep    '\t'
                }
            }

        // publish files without index (would be recorded as list)
        Taxonomy { 
            enabled      true
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            path { indexMeta -> 
                indexMeta.files >> "$taxonomySubdir/" 
                }
            index {
                path   'bridge-taxonomy.csv'
                header true
                sep    '\t'
                }
            }

        // publish index without files (recorded as single directory)
        Main { 
            enabled      true
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            index {
                path   'bridge-main.csv'
                header true
                sep    '\t'
                }
            }

        ////BRANCH_OUTPUT////

    }
