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

////BRANCH_IMPORT////


// SETUP

parseSupplementary( params.supplementary, params )

Parameters = params

EXECUTE  = params.execute.split(',')

RUN_ALL  = EXECUTE.contains('all')

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

        ////BRANCH_RUN////


    /*
    */


    publish: 
    
        ////BRANCH_PUBLISH////

    }


output {

        ////BRANCH_OUTPUT////

    }
