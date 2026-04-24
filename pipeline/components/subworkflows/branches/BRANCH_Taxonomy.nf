
// BRANCH

// IMPORT

include { 
    viewMeta as viewMeta;
    getGroupKey as getGroupKey;
    groupOutputs as groupOutputs;
    } from "$params.importMap.functions/core/Utils"

include { 
    Config_Parse as ParseConfig;
    } from "${params.importMap.subworkflows}/core/Config_Parse"

include {
    STAGING as DownloadCustom;
    } from "${params.importMap.subworkflows}/leaves/custom/download/STAGING_Custom_Download.nf"

////LEAF_IMPORT////


workflow SUBWORKFLOW {


    take: 

        Parameters

        Inputs


    main:

        ////LEAF_START////

        // CUSTOM DOWNLOAD
        
        ConfigDownloadCustom = ParseConfig( Parameters, [software: 'CUSTOM', command: 'DOWNLOAD', branch: 'TAXONOMY'] )
        
        DownloadCustom( Inputs, ConfigDownloadCustom )

        ////LEAF_PARSE_RUN////

        | collect

        | flatMap { coreMetaGroup ->

            // group 1
            def (SOFTWARE1, COMMAND1, BRANCH1, type1) = [ "CUSTOM", "DOWNLOAD", "TAXONOMY", "main" ]
            def outputList1 = coreMetaGroup.OUTPUTS[(SOFTWARE1)][(COMMAND1)][(BRANCH1)][(type1)]
                .flatten()
                .sort()

            def outputMeta1 = [
                (SOFTWARE1) : [
                    (COMMAND1) : [ 
                        (BRANCH1): [
                            (type1) : outputList1,
                            ] ] ],
                                ]

            def groupMeta1 = [
                RUN     : 'taxonomy',
                OUTPUTS : outputMeta1,
                ]

            // group n ...
            
            return [groupMeta1] }

        | set { Processed }


    emit :

        Main = Processed

    }
