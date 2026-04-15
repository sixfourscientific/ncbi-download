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


        // BRANCHES

        println('RUNNING BRANCHES...')
        
        // BRANCH( Inputs|BRANCH.out.Main)

        Taxonomy( Parameters, TAXONOMY ) // | filter { RUN_TAXONOMY }  )

        Search( Parameters, Inputs | filter { RUN_SEARCH }  )

        Count( Parameters, Search.out.Main ) // | filter { RUN_COUNT }  )

        Format( Parameters, Count.out.Main | filter { coreMeta -> coreMeta.AVAILABLE }  )

        ////BRANCH_RUN////

    /*
    */


    publish: 
    
        Files = Taxonomy.out.Main.map{ coreMeta -> 

            def indexMeta = [
                taxonomy: coreMeta.OUTPUTS.CUSTOM.DOWNLOAD.TAXONOMY.main,
                ]
            
            def indexMetaNew = prepBridge( coreMeta: coreMeta, indexMeta: indexMeta, INTERMEDIATE: false, UPDATE: false )            
            
            return indexMetaNew }


        Index = Taxonomy.out.Main.map{ coreMeta -> 

            def indexMeta = [
                datasets: "${workflow.outputDir}/$datasetsSubdir",
                taxonomy: "${workflow.outputDir}/$taxonomySubdir",
                ]
            
            def indexMetaNew = prepBridge( coreMeta: coreMeta, indexMeta: indexMeta, INTERMEDIATE: false, UPDATE: false )            
            
            return indexMetaNew }

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

        ////BRANCH_PUBLISH////

    }


output {

        // publish files without index (would be recorded as list)
        Files { 
            enabled      true
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            path { indexMeta -> 
                indexMeta.taxonomy >> "$taxonomySubdir/" 
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

        ////BRANCH_OUTPUT////

    }
