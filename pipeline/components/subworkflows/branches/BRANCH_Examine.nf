
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

                def queryID = coreMeta.entry
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

                        // sort IDs mapped to Accessions
                        // N.B. will prioritise more specific taxon names (i.e. species > genus) but taxid will be unpredictable
                        def mappedList = accessionMap[accession]
                            .sort{ label1, label2 -> label2 <=> label1 }

                        // identify first entry mapped to accession
                        def entryFirst = mappedList.first()

                        // check entry mapped order
                        def mappedPriority = entryFirst.equals(coreMeta.entry)

                        // count accession mappings to identify duplicated
                        def mappedCount = mappedList.size()

                        def coreMetaNew = coreMeta + [
                            TAG      : null, // negates race condition later at filter
                            mapped   : mappedCount,
                            PRIORITY : mappedPriority, 
                            ]

                        return coreMetaNew }

                return splitMetaList }

        ////LEAF_PARSE_RUN////

        | set { Processed }
    

    emit :

        Main = Processed

    }
