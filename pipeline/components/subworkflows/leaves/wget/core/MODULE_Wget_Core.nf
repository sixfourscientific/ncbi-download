
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
                path (INPUT),
                path (OPTIONAL),
                val  (Arguments)

    output:

        tuple   val  (CoreMeta),
                path ('{*.txt,**/*.txt}'),

                emit: Main

    // MAIN

    script:

        println(">>TASK>> $task.process $task.tag; ATTEMPT: $task.attempt | CPUS: $task.cpus (max: $task.resourceLimits.cpus) | MEMORY: $task.memory (max: $task.resourceLimits.memory) | TIME: $task.time (max: $task.resourceLimits.time) | VERSION: $task.ext.version | EXEC: $task.ext.executable\n")

        """

        mkdir -p subDir
        echo 'TEST' > OUTPUT1.txt
        echo 'TEST' > subDir/OUTPUT2.txt

        """

    }

/* 

VERSION: X.X

HELP

*/
