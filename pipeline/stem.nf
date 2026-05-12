#!/usr/bin/env nextflow

/* enable dsl syntax extension (should be applied by default) */
nextflow.enable.dsl = 2




// IMPORTS

import java.nio.file.Files

// FUNCTIONS

params.PUBLISH = true

params.importMap = [ 'subworkflows', 'functions' ]

        .collectEntries { subDir -> 

                def subPath = [ workflow.projectDir, 'components', subDir, ]
                
                        .join('/')
                
                return [ (subDir) : subPath ] }


include { 
    parseSupplementary as parseSupplementary;
    viewMeta as viewMeta;
    prepBridge as prepBridge;
    parseUrl as parseUrl;
    makeTag as makeTag;
    } from "$params.importMap.functions/core/Utils"

// SUBWORKFLOWS

include { 
    Info_Parse as ParseInfo;
    } from "${params.importMap.subworkflows}/core/Info_Parse"

include { 
    Subsets_Parse as ParseSubsets;
    } from "${params.importMap.subworkflows}/core/Subsets_Parse"

include {
    SUBWORKFLOW as Taxonomy;
    } from "${params.importMap.subworkflows}/branches/BRANCH_Taxonomy"

include {
    SUBWORKFLOW as Query;
    } from "${params.importMap.subworkflows}/branches/BRANCH_Query"

include {
    SUBWORKFLOW as Count;
    } from "${params.importMap.subworkflows}/branches/BRANCH_Count"

include {
    SUBWORKFLOW as Format;
    } from "${params.importMap.subworkflows}/branches/BRANCH_Format"

include {
    SUBWORKFLOW as Split;
    } from "${params.importMap.subworkflows}/branches/BRANCH_Split"

include {
    SUBWORKFLOW as Examine;
    } from "${params.importMap.subworkflows}/branches/BRANCH_Examine"

include {
    SUBWORKFLOW as Fetch;
    } from "${params.importMap.subworkflows}/branches/BRANCH_Fetch"

include {
    SUBWORKFLOW as Filter;
    } from "${params.importMap.subworkflows}/branches/BRANCH_Filter"

include {
    SUBWORKFLOW as Collect;
    } from "${params.importMap.subworkflows}/branches/BRANCH_Collect"

include {
    SUBWORKFLOW as Divide;
    } from "${params.importMap.subworkflows}/branches/BRANCH_Divide"

////BRANCH_IMPORT////


// SETUP

taxonomySubdir = 'taxonomy'
datasetsSubdir = 'datasets'

parseSupplementary( params.supplementary, params )

Parameters = params

EXECUTE  = params.execute.split(',')

// RUN_TAXONOMY = RUN_ALL ?: EXECUTE.contains('taxonomy')

RUN_QUERY = EXECUTE.contains('query')

RUN_FETCH = EXECUTE.contains('fetch')

RUN_DIVIDE = EXECUTE.contains('divide')

////BRANCH_FILTER////


workflow { 

    main:

        println('PARSING INPUTS...')

        // MAIN

        def InputMeta = (params.INPUT?.MAIN ?: [:]) + [
            INFO     : params.inputs,
            TYPE     : "TARGETS",
            DETAILED : true,
            ID_FIELD : ['taxon','accession'],
            ]

        Inputs = ParseInfo( InputMeta )

            | map { coreMeta ->

                def (entryType) = coreMeta.INFO.FIELDS

                def coreMetaNew = [
                    ID    : coreMeta.ID,
                    entry : coreMeta[(entryType)],
                    type  : entryType,
                    ]

                return coreMetaNew }

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
        Count( Parameters, Query.out.Main )

        // reformat json/jsonl as tsv
        Format( Parameters, Count.out.Main | filter { coreMeta -> coreMeta.AVAILABLE }  )

        // seperate individual reports
        Split( Parameters, Format.out.Main )

        // examine accessions mapped to query IDs 
        Examine( Parameters, Split.out.Main )

        // filter accessions according to criteria
        Filter( Parameters, Examine.out.Main )


        // FETCH

        // collect accessions
        Collect( Parameters, Filter.out.Main )

        // subset accesssions into batches
        ParseSubsets( Parameters, Collect.out.Main )

        // download datasets
        Fetch( Parameters, ParseSubsets.out.Main | filter { RUN_FETCH }  )

        // divide datasets
        Divide( Parameters, Fetch.out.Main )


        // obtain supplementary taxonomy files (if provided)
        Taxonomy( Parameters, TAXONOMY )

        ////BRANCH_RUN////



    publish: 
    
        Query = Query.out.Main.map{ coreMeta -> 

            def indexMeta = [:]
            
            def indexMetaNew = prepBridge( 
                coreMeta  : coreMeta, 
                indexMeta : indexMeta, 
                BASIC     : false, 
                UPDATE    : false, 
                INTERIM   : false,
                )      
            
            return indexMetaNew }

        Count = Count.out.Main.map{ coreMeta -> 
        
            def indexMeta = [:]
            
            def indexMetaNew = prepBridge( 
                coreMeta  : coreMeta, 
                indexMeta : indexMeta, 
                BASIC     : false, 
                UPDATE    : false, 
                INTERIM   : false,
                )      
            
            return indexMetaNew }

        Format = Format.out.Main.map{ coreMeta -> 

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

        Split = Split.out.Main.map{ coreMeta -> 

            def indexMeta = [:]
            
            def indexMetaNew = prepBridge( 
                coreMeta  : coreMeta, 
                indexMeta : indexMeta, 
                BASIC     : false, 
                UPDATE    : false, 
                INTERIM   : false,
                )      
            
            return indexMetaNew }

        Examine = Examine.out.Main.map{ coreMeta -> 

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

        Filter = Filter.out.Main.map{ coreMeta -> 
        
            def indexMeta = [:]
            
            def indexMetaNew = prepBridge( 
                coreMeta  : coreMeta, 
                indexMeta : indexMeta, 
                BASIC     : false, 
                UPDATE    : false, 
                INTERIM   : false,
                )      

            return indexMetaNew }

        Fetch = Divide.out.Main.map{ coreMeta -> 

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

        Taxonomy = Taxonomy.out.Main.map{ coreMeta -> 

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

        Main = Divide.out.Main.unique{ coreMeta -> coreMeta.TAG }.map{ coreMeta -> 

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


        Collect = Collect.out.Main.map{ coreMeta -> 
        
            def indexMeta = [:]
            
            def indexMetaNew = prepBridge( 
                coreMeta  : coreMeta, 
                indexMeta : indexMeta, 
                BASIC     : false, 
                UPDATE    : false, 
                INTERIM   : false,
                )      
            
            return indexMetaNew }

        Divide = Divide.out.Main.map{ coreMeta -> 
        
            def indexMeta = [:]
            
            def indexMetaNew = prepBridge( 
                coreMeta  : coreMeta, 
                indexMeta : indexMeta, 
                BASIC     : false, 
                UPDATE    : false, 
                INTERIM   : false,
                )      
            
            return indexMetaNew }

        ////BRANCH_PUBLISH////

    }


output {

        Query { 
            enabled      false
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            path { indexMeta -> 
                return "query/$indexMeta.run" }
            index {
                path   'bridge-query.csv'
                header true
                sep    '\t'
                }
            }

        Count { 
            enabled      false
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            path { indexMeta -> 
                return "count/$indexMeta.run" }
            index {
                path   'bridge-count.csv'
                header true
                sep    '\t'
                }
            }

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

        Split { 
            enabled      false
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            path { indexMeta -> 
                return "split/$indexMeta.run" }
            index {
                path   'bridge-split.csv'
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

        Filter { 
            enabled      false
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            path { indexMeta -> 
                return "filter/$indexMeta.run" }
            index {
                path   'bridge-filter.csv'
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

        Collect { 
            enabled      false
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            path { indexMeta -> 
                return "collect/$indexMeta.run" }
            index {
                path   'bridge-collect.csv'
                header true
                sep    '\t'
                }
            }

        Divide { 
            enabled      false
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            path { indexMeta -> 
                return "divide/$indexMeta.run" }
            index {
                path   'bridge-divide.csv'
                header true
                sep    '\t'
                }
            }

        ////BRANCH_OUTPUT////

    }
