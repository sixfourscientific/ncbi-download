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
    getUrlTag as getUrlTag;
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
    SUBWORKFLOW as Search;
    } from "${params.importMap.subworkflows}/branches/BRANCH_Search"

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

////BRANCH_IMPORT////


// SETUP

taxonomySubdir = 'taxonomy'
datasetsSubdir = 'datasets'

parseSupplementary( params.supplementary, params )

Parameters = params

EXECUTE  = params.execute.split(',')

RUN_ALL  = EXECUTE.contains('all')

// RUN_TAXONOMY = RUN_ALL ?: EXECUTE.contains('taxonomy')

RUN_SEARCH = RUN_ALL ?: EXECUTE.contains('search')

RUN_COUNT = RUN_ALL ?: EXECUTE.contains('count')

RUN_FORMAT = RUN_ALL ?: EXECUTE.contains('format')

RUN_SPLIT = RUN_ALL ?: EXECUTE.contains('split')

RUN_EXAMINE = RUN_ALL ?: EXECUTE.contains('examine')

RUN_FETCH = RUN_ALL ?: EXECUTE.contains('fetch')

RUN_FILTER = RUN_ALL ?: EXECUTE.contains('filter')

////BRANCH_FILTER////


workflow { 

    main:

        println('PARSING INPUTS...')

        // SAMPLES

        def InputMeta = params.INPUT.SAMPLES + [
            INFO     : params.samples,
            INFO_ID  : "SAMPLES",
            ]

        Inputs = ParseInfo( InputMeta )
            
            | map { coreMeta ->

                def (entry) = coreMeta.entrySet()
                
                def runTag = entry.value.toString().replaceAll( "\\s", "_" )
                
                def coreMetaNew = [
                    RUN  : runTag,
                    id   : entry.value,
                    type : entry.key,
                    ]

                return coreMetaNew }

        // SUPPLEMENTARY

        def TaxonomyMeta = [
            INFO     : params.TAXONOMY,
            ID       : "TAXONOMY",
            ]

        TAXONOMY = ParseInfo( TaxonomyMeta ) 

            | filter{ coreMeta -> coreMeta }
        
            // create custom run tag from parsed url
            | map { coreMeta ->

                def runTag = getUrlTag(coreMeta['url'])

                def coreMetaNew = coreMeta + [
                    RUN : runTag,
                    ]

                return coreMetaNew }
                
        // SUBSETS

        def BatchMeta = params.BATCH ?: [:] + [
            NAME      : 'downloads',
            BATCHSIZE : 2,
            TARGETS   : [['id'],['report','accession']],
            HEADER    : false,
            VERBOSE   : false,
            ]


        // BRANCHES

        println('RUNNING BRANCHES...')
        
        // BRANCH( Inputs|BRANCH.out.Main)

        // obtain taxonomy files
        Taxonomy( Parameters, TAXONOMY )

        // obtain datasets summary
        Search( Parameters, Inputs | filter { RUN_SEARCH || RUN_FETCH }  )

        // examine report availability
        Count( Parameters, Search.out.Main )

        // reformat json/jsonl as tsv
        Format( Parameters, Count.out.Main | filter { coreMeta -> coreMeta.AVAILABLE }  )

        // seperate individual reports
        Split( Parameters, Format.out.Main )

        // examine accessions mapped to query IDs 
        Examine( Parameters, Split.out.Main )

        // filter accessions according to criteria
        Filter( Parameters, Examine.out.Main )

        // group accessions
        Grouped = Filter.out.Main
            
            // sort by (i) queryID & (ii) accession
            | toSortedList { coreMeta1, coreMeta2 ->  

                // smallest -> largest
                coreMeta1.id               <=> coreMeta2.id
                ?:
                // smallest -> largest
                coreMeta1.report.accession <=> coreMeta2.report.accession }

            // stage for subsetting
            | map { coreMetaList ->

                def groupMeta = [
                    BATCH    : BatchMeta,
                    GROUPED  : coreMetaList,
                    ]

                return groupMeta }

        // subset accesssions into batches
        ParseSubsets( Parameters, Grouped )

        // download datasets
        Fetch( Parameters, ParseSubsets.out.Main | filter { RUN_FETCH }  )

        // split archives
        Archives = Fetch.out.Main
            
            | toSortedList{ coreMeta1, coreMeta2 -> coreMeta1.BATCH.INDEX <=> coreMeta2.BATCH.INDEX }

            | flatten()

            | flatMap { coreMeta ->

                def subPath = [ "DATASETS", "DOWNLOAD", "FETCH", "main" ]

                def fileList = subPath.inject(coreMeta.OUTPUTS) { acc, key -> acc[key] }

                def splitMetaList = fileList
                    .sort{ first, second -> first <=> second}
                    .withIndex()
                    .collect { output, idx ->

                        def batchTag = "BATCH-${coreMeta.BATCH.INDEX}"

                        def splitTag = "$batchTag-SPLIT-${idx+1}"
                        
                        def outputMeta = subPath
                            .reverse()
                            .inject(output) { acc, key -> [(key): acc] }

                        def splitMeta = [
                            RUN     : splitTag,
                            OUTPUTS : outputMeta,
                            ]

                        return splitMeta }

                return splitMetaList }

        ////BRANCH_RUN////

    /*
    */


    publish: 
    
        Search = Search.out.Main.map{ coreMeta -> 
        
            def indexMeta = [:]
            
            def indexMetaNew = prepBridge( coreMeta: coreMeta, indexMeta: indexMeta, INTERMEDIATE: false, UPDATE: false )            
            
            return indexMetaNew }

        Count = Count.out.Main.map{ coreMeta -> 
        
            def indexMeta = [:]
            
            def indexMetaNew = prepBridge( coreMeta: coreMeta, indexMeta: indexMeta, INTERMEDIATE: false, UPDATE: false )            
            
            return indexMetaNew }

        Format = Format.out.Main.map{ coreMeta -> 

            def indexMeta = [:]
            
            def indexMetaNew = prepBridge( coreMeta: coreMeta, indexMeta: indexMeta, INTERMEDIATE: false, UPDATE: false )            
            
            return indexMetaNew }

        Split = Split.out.Main.map{ coreMeta -> 
        
            def indexMeta = [:]
            
            def indexMetaNew = prepBridge( coreMeta: coreMeta, indexMeta: indexMeta, INTERMEDIATE: false, UPDATE: false )            
            
            return indexMetaNew }

        Examine = Examine.out.Main.map{ coreMeta -> 
        
            def indexMeta = [:]
            
            def indexMetaNew = prepBridge( coreMeta: coreMeta, indexMeta: indexMeta, INTERMEDIATE: false, UPDATE: false )            
            
            return indexMetaNew }

        Filter = Filter.out.Main.map{ coreMeta -> 
        
            def indexMeta = [:]
            
            def indexMetaNew = prepBridge( coreMeta: coreMeta, indexMeta: indexMeta, INTERMEDIATE: false, UPDATE: false )            

            return indexMetaNew }

        Fetch = Archives.map{ coreMeta -> 

            def indexMeta = [
                files : coreMeta.OUTPUTS.DATASETS.DOWNLOAD.FETCH.main,
                ]
            
            def indexMetaNew = prepBridge( coreMeta: coreMeta, indexMeta: indexMeta, INTERMEDIATE: false, UPDATE: false )            

            return indexMetaNew }

        Taxonomy = Taxonomy.out.Main.map{ coreMeta -> 

            def indexMeta = [
                files : coreMeta.OUTPUTS.CUSTOM.DOWNLOAD.TAXONOMY.main,
                ]
            
            def indexMetaNew = prepBridge( coreMeta: coreMeta, indexMeta: indexMeta, INTERMEDIATE: false, UPDATE: false )            
            
            return indexMetaNew }

        Index = Fetch.out.Main.first().map{ coreMeta -> 

            // N.B. general bridge using first element

            def indexMeta = [
                datasets: "${workflow.outputDir}/$datasetsSubdir",
                taxonomy: params.TAXONOMY ? "${workflow.outputDir}/$taxonomySubdir" : 'NA',
                ]
            
            def indexMetaNew = prepBridge( coreMeta: coreMeta, indexMeta: indexMeta, INTERMEDIATE: false, UPDATE: false )            
            
            return indexMetaNew }


        ////BRANCH_PUBLISH////

    }


output {

        Search { 
            enabled      false
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            path { indexMeta -> 
                return "search/$indexMeta.run" }
            index {
                path   'bridge-search.csv'
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
            enabled      false
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            path { indexMeta -> 
                return "format/$indexMeta.run" }
            index {
                path   'bridge-format.csv'
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
            enabled      false
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            path { indexMeta -> 
                return "examine/$indexMeta.run" }
            index {
                path   'bridge-examine.csv'
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
                indexMeta.files >> "$datasetsSubdir/" 
                }
            index {
                path   'bridge-datasets.csv'
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
        Index { 
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
