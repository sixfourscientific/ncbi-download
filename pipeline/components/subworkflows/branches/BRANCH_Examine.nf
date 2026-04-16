
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

        accessionMap = [:]

        Inputs 
            
            // examine individually
            | map { coreMeta ->

                def queryID = coreMeta.id
                def accession = coreMeta.report.accession
                    
                // create accession entry
                if ( !accessionMap.containsKey(accession) ){
                    accessionMap.putAt(accession, [])}

                // store additional labels
                if ( !accessionMap[accession].contains(queryID) ){
                    accessionMap[accession].add(queryID)}  

                return coreMeta }

            // pause
            | collect 

            // examine collectively
            | flatMap{ coreMetaList ->

                def splitMetaList = coreMetaList
                
                    .collect{ coreMeta ->

                        def accession = coreMeta.report.accession

                        // count accession mappings to identify duplicated
                        def mappedCount = accessionMap[accession].size()
                
                        def coreMetaNew = coreMeta + [
                            mapped : mappedCount,
                            ]

                        return coreMetaNew }

                return splitMetaList }

        ////LEAF_PARSE_RUN////

        | set { Processed }
    

    emit :

        Main = Processed

    }
