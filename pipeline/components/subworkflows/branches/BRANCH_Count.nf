
// BRANCH

// IMPORT

include { 
    viewMeta as viewMeta;
    } from "$params.importMap.functions/core/Utils"

include { 
    Config_Parse as ParseConfig;
    } from "${params.importMap.subworkflows}/core/Config_Parse"

////LEAF_IMPORT////


workflow SUBWORKFLOW {


    take: 

        Parameters

        Inputs


    main:

        ////LEAF_START////

        Inputs 

            | map { coreMeta ->

                def summaryFile = new File(coreMeta.OUTPUTS.DATASETS.SUMMARY.QUERY.main.toString())

                def count = 0

                // skip empty files                
                if (summaryFile.length() > 0){

                    // parse json file
                    def jsonSlurper = new groovy.json.JsonSlurper()

                    def summaryMap = jsonSlurper.parse(summaryFile)

                    // count jsonl/json entries
                    count = summaryFile.toString().endsWith ('.jsonl')
                        ? summaryFile.readLines().size()
                        : summaryMap['total_count']

                    }

                def coreMetaNew = coreMeta + [
                    total : count,
                    AVAILABLE : !count.toInteger().equals(0)
                    ]

                return coreMetaNew }

        ////LEAF_PARSE_RUN////

        | set { Processed }


    emit :

        Main = Processed

    }
