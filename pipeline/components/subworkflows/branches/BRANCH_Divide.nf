
// BRANCH

// IMPORT

include { 
    viewMeta as viewMeta;
    splitOutputs as splitOutputs;
    } from "../../functions/core/Utils"

include { 
    Config_Parse as ParseConfig;
    } from "../core/Config_Parse"

////LEAF_IMPORT////


workflow SUBWORKFLOW {


    take: 

        Parameters

        Inputs


    main:

        ////LEAF_START////

        Inputs
            
            | toSortedList{ coreMeta1, coreMeta2 -> 
            
                coreMeta1.BATCH.INDEX <=> coreMeta2.BATCH.INDEX }

            | flatten()

            | flatMap { coreMeta ->

                def pathList = [ "DATASETS", "DOWNLOAD", "FETCH", "main" ]

                def coreMetaNew = coreMeta + [
                    BATCH   : null,
                    GROUPED : null,
                    ID      : null,
                    ]

                def splitMetaList = splitOutputs(
                    coreMeta  : coreMetaNew,
                    pathList  : pathList,
                    splitTag  : null,
                    delimiter : '-',
                    index     : false,
                    )

                return splitMetaList }

        | map { coreMeta ->

            def archiveTag = file(coreMeta.OUTPUTS.DATASETS.DOWNLOAD.FETCH.main)
                .getBaseName()

            def coreMetaNew = coreMeta + [
                ID : archiveTag,
                ]

            return coreMetaNew }

        ////LEAF_PARSE_RUN////

        | set { Processed }


    emit :

        Processed

    }
