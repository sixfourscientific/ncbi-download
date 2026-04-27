
// BRANCH

// IMPORT

include { 
    viewMeta as viewMeta;
    } from "$params.importMap.functions/core/Utils"

include { 
    Config_Parse as ParseConfig;
    } from "${params.importMap.subworkflows}/core/Config_Parse"

include {
    STAGING as SummaryDatasets;
    } from "${params.importMap.subworkflows}/leaves/datasets/summary/genome/STAGING_Datasets_Summary.nf"

////LEAF_IMPORT////


workflow SUBWORKFLOW {


    take: 

        Parameters

        Inputs


    main:

        ////LEAF_START////

        // DATASETS SUMMARY
        
        ConfigSummaryDatasets = ParseConfig( Parameters, [software: 'DATASETS', command: 'SUMMARY', branch: 'QUERY'] )
        
        SummaryDatasets( Inputs, ConfigSummaryDatasets )

        ////LEAF_PARSE_RUN////

        | set { Processed }


    emit :

        Main = Processed

    }
