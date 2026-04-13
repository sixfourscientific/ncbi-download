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
    } from "$params.importMap.functions/core/Utils"

// SUBWORKFLOWS

include { 
    Info_Parse as ParseInfo;
    } from "${params.importMap.subworkflows}/core/Info_Parse"

include {
    SUBWORKFLOW as Taxonomy;
    } from "${params.importMap.subworkflows}/branches/BRANCH_Taxonomy"

////BRANCH_IMPORT////


// SETUP

parseSupplementary( params.supplementary, params )

Parameters = params

EXECUTE  = params.execute.split(',')

RUN_ALL  = EXECUTE.contains('all')

RUN_TAXONOMY = RUN_ALL ?: EXECUTE.contains('taxonomy')

////BRANCH_FILTER////


workflow { 

    main:

        println('PARSING INPUTS...')

        // SAMPLES

        def InputMeta = params.INPUT.SAMPLES + [
            INFO     : params.samples,
            INFO_ID  : "SAMPLES",
            DETAILED : true,
            ]

        Inputs = ParseInfo( InputMeta )

        // SUPPLEMENTARY

        def SUPPLEMENTARYMeta = [
            INFO : params.SUPPLEMENTARY,
            ID   : "SUPPLEMENTARY",
            ]

        SUPPLEMENTARY = ParseInfo( SUPPLEMENTARYMeta )


        // BRANCHES

        println('RUNNING BRANCHES...')
        
        // BRANCH( Inputs|BRANCH.out.Main)

        Taxonomy( Parameters, Inputs | filter { RUN_TAXONOMY }  )

        ////BRANCH_RUN////


    /*
    */


    publish: 
    
        Taxonomy = Taxonomy.out.Main.map{ coreMeta -> 
        
            def indexMeta = [:]
            
            def indexMetaNew = prepBridge( coreMeta: coreMeta, indexMeta: indexMeta, INTERMEDIATE: false, UPDATE: false )            
            
            return indexMetaNew }

        ////BRANCH_PUBLISH////

    }


output {

        Taxonomy { 
            enabled      false
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            path { indexMeta -> 
                return "taxonomy/$indexMeta.run" }
            index {
                path   'bridge-taxonomy.csv'
                header true
                sep    '\t'
                }
            }

        ////BRANCH_OUTPUT////

    }
