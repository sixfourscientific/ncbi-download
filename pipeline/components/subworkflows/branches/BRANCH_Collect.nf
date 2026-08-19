
// BRANCH

// IMPORT

include { 
    viewMeta as viewMeta;
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

        // SUBSETS

        def BatchMeta = (Parameters.BATCH ?: [:]) + [
            NAME      : 'downloads',
            TARGETS   : [['entry'],['report','accession']],
            HEADER    : false,
            VERBOSE   : false,
            ]

        Inputs
        
            // sort by (i) queryID & (ii) accession
            | toSortedList { coreMeta1, coreMeta2 ->  

                // smallest -> largest
                coreMeta1.entry            <=> coreMeta2.entry
                ?:
                // smallest -> largest
                coreMeta1.report.accession <=> coreMeta2.report.accession }

            // stage for subsetting
            | map { coreMetaList ->

                def groupMeta = [
                    BATCH    : BatchMeta,
                    GROUPED  : coreMetaList,
                    ]

                return groupMeta }

        ////LEAF_PARSE_RUN////

        | set { Processed }


    emit :

        Processed

    }
