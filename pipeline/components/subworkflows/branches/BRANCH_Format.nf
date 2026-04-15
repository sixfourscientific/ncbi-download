
// BRANCH

// IMPORT

include { 
    viewMeta as viewMeta;
    } from "$params.importMap.functions/core/Utils"

include { 
    Config_Parse as ParseConfig;
    } from "${params.importMap.subworkflows}/core/Config_Parse"

include {
    STAGING as TabulateCustom;
    } from "${params.importMap.subworkflows}/leaves/custom/tabulate/STAGING_Custom_Tabulate.nf"

////LEAF_IMPORT////


workflow SUBWORKFLOW {


    take: 

        Parameters

        Inputs


    main:

        ////LEAF_START////

        // CUSTOM TABULATE
        
        ConfigTabulateCustom = ParseConfig( Parameters, [software: 'CUSTOM', command: 'TABULATE', branch: 'FORMAT'] )
        
        TabulateCustom( Inputs, ConfigTabulateCustom )

        ////LEAF_PARSE_RUN////

        | set { Processed }


    emit :

        Main = Processed

    }
