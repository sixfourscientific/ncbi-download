
// BRANCH

// IMPORT

include { 
    viewMeta as viewMeta;
    getGroupKey as getGroupKey;
    groupOutputs as groupOutputs;
    } from "../../functions/core/Utils"

include { 
    Config_Parse as ParseConfig;
    } from "../core/Config_Parse"

include {
    STAGING as DownloadCustom;
    } from "../leaves/custom/download/STAGING_Custom_Download.nf"

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

        | set { Processed }


    emit :

        Processed

    }
