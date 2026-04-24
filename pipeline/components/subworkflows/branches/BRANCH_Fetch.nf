
// BRANCH

// IMPORT

include { 
    viewMeta as viewMeta;
    } from "$params.importMap.functions/core/Utils"

include { 
    Config_Parse as ParseConfig;
    } from "${params.importMap.subworkflows}/core/Config_Parse"

include {
    STAGING as DownloadDatasets;
    } from "${params.importMap.subworkflows}/leaves/datasets/download/genome/batch/STAGING_Datasets_Download.nf"

////LEAF_IMPORT////


workflow SUBWORKFLOW {


    take: 

        Parameters

        Inputs


    main:

        ////LEAF_START////

        // DATASETS DOWNLOAD
        
        ConfigDownloadDatasets = ParseConfig( Parameters, [software: 'DATASETS', command: 'DOWNLOAD', branch: 'FETCH'] )
        
        DownloadDatasets( Inputs, ConfigDownloadDatasets )

        ////LEAF_PARSE_RUN////

        | collect

        | flatMap { coreMetaGroup ->

            // group 1
            def (SOFTWARE1, COMMAND1, BRANCH1, type1) = [ "DATASETS", "DOWNLOAD", "FETCH", "main" ]
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
                RUN     : 'datasets',
                OUTPUTS : outputMeta1,
                ]

            // group n ...
            
            return [groupMeta1] }

        | set { Processed }


    emit :

        Main = Processed

    }
