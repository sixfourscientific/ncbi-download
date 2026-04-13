
// BRANCH

// IMPORT

include { 
    viewMeta as viewMeta;
    } from "$params.importMap.functions/core/Utils"

include { 
    Config_Parse as ParseConfig;
    } from "${params.importMap.subworkflows}/core/Config_Parse"

include {
    STAGING as CoreWget;
    } from "${params.importMap.subworkflows}/leaves/wget/core/STAGING_Wget_Core.nf"

////LEAF_IMPORT////


workflow SUBWORKFLOW {


    take: 

        Parameters

        Inputs


    main:

        ////LEAF_START////

        // WGET CORE
        
        ConfigCoreWget = ParseConfig( Parameters, [software: 'WGET', command: 'CORE', branch: 'TAXONOMY'] )
        
        CoreWget( Inputs, ConfigCoreWget )

        ////LEAF_PARSE_RUN////

        | set { Processed }


    emit :

        Main = Processed

    }
