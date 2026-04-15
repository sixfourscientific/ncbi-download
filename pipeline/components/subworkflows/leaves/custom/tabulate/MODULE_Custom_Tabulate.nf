
include { 
    formatArguments as formatArguments;
    } from "$params.importMap.functions/core/Utils"

process MODULE {

    // SETUP

    tag "$CoreMeta.RUN"

    label workflow.profile in params.profileLabels 
        ? workflow.profile.toUpperCase()
        : 'DEFAULT'

    // EXTRA

    ext version : {

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
                path (Summary),
                path (OPTIONAL),
                val  (Arguments)

    output:

        tuple   val  (CoreMeta),
                path ('*.tsv'),

                emit: Main

    // MAIN

    script:

        """

        jsonl2table.py -i $Summary

        """

    }

/* 

VERSION: X.X

HELP

*/
