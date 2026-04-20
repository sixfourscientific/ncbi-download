
// IMPORT

include { 
    parseSubsets as parseSubsets;
    } from "$params.importMap.functions/core/Files"


include { 
    flattenMeta as flattenMeta;
    } from "$params.importMap.functions/core/Utils"


workflow Subsets_Parse {

    take: 
    
        Parameters

        Grouped

    main:

        Grouped 

            | flatMap { groupMeta ->

                def subsetList = parseSubsets( 
                    grouped    : groupMeta,
                    keepHeader : false,
                    )
            
                return subsetList }
        
        | set { Subsets }

        // record subset in file
        Subsets

            | collectFile(
                newLine : true,
                    ){ coreMeta ->

                    def fileName = coreMeta.SUBSET.FILE

                    def text = coreMeta.GROUPED

                            .withIndex()

                            .collect{ entry, idx ->

                                def entryFlat = flattenMeta(entry)

                                def keys = entryFlat
                                    .keySet()
                                    .join('\t')

                                def values = entryFlat
                                    .values()
                                    .join('\t')

                                def lines = ( coreMeta.SUBSET.HEADER && idx.equals(0) )
                                    ? "$keys\nt$values"
                                    : values

                                return lines }

                            .join('\n')

                        return [ fileName, text, ] }

            | set { Files }

        // recombine subset with file
        Subsets

        | mix ( Files ) 
        
                | map { obj ->
                
                    def groupID = obj instanceof Map
                        ? obj.SUBSET.FILE
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

                    def (coreMeta) = metaList

                    def (filePath) = nonMetaList

                    def subsetMeta = coreMeta.SUBSET + [
                        FILE: filePath,
                        ]

                    def coreMetaNew = coreMeta + [
                        SUBSET : subsetMeta,
                        ]

                    return coreMetaNew }
        
        | set { Processed }

    emit:

        Main = Processed

    }