
// IMPORT

include { 
    parseSubsets as parseSubsets;
    } from "$params.importMap.functions/core/Files"


include { 
    getSubMap as getSubMap;
    flattenMap as flattenMap;
    makeTag as makeTag;
    } from "$params.importMap.functions/core/Utils"


workflow Subsets_Parse {

    take: 
    
        Parameters

        Grouped

    main:

        Grouped 

            | flatMap { groupMeta ->

                def subsetList = parseSubsets( 
                    batch   : groupMeta.BATCH,
                    grouped : groupMeta.GROUPED,
                    )

                return subsetList }
        
        | set { Subsets }

        // record subset in batch file
        Subsets

            | collectFile(
                newLine : true,                
                ){ subsetMeta ->

                    def fileName = subsetMeta.BATCH.FILE

                    def nestList = subsetMeta.BATCH.TARGETS

                    def text = subsetMeta.GROUPED

                        .withIndex()

                        .collect{ elementMeta, idx ->

                            // extract submap as required
                            def relevantMeta = nestList
                                ? getSubMap(elementMeta, nestList)
                                : elementMeta

                            // flatten nested map structure
                            def flatMeta = flattenMap(relevantMeta)

                            def keys = flatMeta
                                .keySet()
                                .join('\t')

                            def values = flatMeta
                                .values()
                                .join('\t')

                            // return header (keys) as required
                            def lines = ( subsetMeta.BATCH.HEADER && idx.equals(0) )
                                ? "$keys\n$values"
                                : values

                            return lines }

                            .join('\n')

                        return [ fileName, text, ] }

            | set { Files }

        // recombine subset with batch file
        Subsets

        | mix ( Files ) 
        
                | map { obj ->
                
                    // check if meta or file
                    def groupID = obj instanceof Map
                        ? obj.BATCH.FILE
                        : file(obj).getName() 

                    return [
                        groupID,
                        obj,
                        ] }

        | groupTuple( by:0 )

                | map { groupID, infoGroup ->
                    
                    def ( metaList, nonMetaList ) = infoGroup.split{ obj -> obj instanceof Map }
                    
                    assert metaList.size()    == 1, 'Multiple meta objects regrouped'

                    assert nonMetaList.size() == 1, 'Multiple batches regrouped'

                    def (subsetMeta) = metaList

                    def (filePath) = nonMetaList

                    def idNew = makeTag(
                        tags      : [ subsetMeta.BATCH.NAME, 'BATCH', subsetMeta.BATCH.INDEX ], 
                        delimiter : '-',
                        )

                    def batchMeta = subsetMeta.BATCH + [
                        FILE: filePath,
                        ]

                    def subsetMetaNew = subsetMeta + [
                        ID    : idNew,
                        BATCH : batchMeta,
                        ]

                    return subsetMetaNew }
        
        | set { Processed }



    emit:

        Main = Processed

    }