
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
        
            // retain prioritised accessions (if duplicated via taxon)
            | filter { coreMeta -> coreMeta.PRIORITY }

            // remove duplicate accessions (if duplicated via taxon or accession)
            | unique { coreMeta -> coreMeta.report.accession }            

        ////LEAF_PARSE_RUN////

        | set { Processed }


    emit :

        Main = Processed

    }
