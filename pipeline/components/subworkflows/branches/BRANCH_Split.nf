
// BRANCH

// IMPORT

include { 
    viewMeta as viewMeta;
    makeTag as makeTag;
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


        | flatMap { coreMeta ->

            def (SOFTWARE, COMMAND, BRANCH, type) = [ "CUSTOM", "TABULATE", "FORMAT", "main" ]

            def splitMetaList = coreMeta.OUTPUTS[(SOFTWARE)][(COMMAND)][(BRANCH)][(type)]

                // extract table entries
                .splitCsv( 
                    header : true,
                    skip   : 0,
                    sep    : '\t' 
                    )
                
                .withIndex()

                // cycle table entries...
                .collect{entry, idx ->

                    def idxTag = idx+1

                    def idNew = makeTag(
                        tags      : [ coreMeta.ID, idxTag, ],
                        delimiter : '-',
                        )

                    // store record number & report info
                    def splitMeta = coreMeta + [
                        ID      : idNew,
                        record  : idxTag,
                     // report  : entry,
                        report  : [ accession : entry.accession ], // simplified report info
                        OUTPUTS : null,
                        ]

                    return splitMeta }

            return splitMetaList }
        
        ////LEAF_PARSE_RUN////

        | set { Processed }


    emit :

        Main = Processed

    }
