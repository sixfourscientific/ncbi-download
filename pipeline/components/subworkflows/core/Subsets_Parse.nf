
// IMPORT

include { 
    parseSubsets as parseSubsets;
    } from "$params.importMap.functions/core/Files"

workflow Subsets_Parse {

    take: 
    
        Parameters

        Grouped

    main:

        Grouped 

            | flatMap { groupMeta ->

                def subsetList = parseSubsets( 
                    grouped : groupMeta,
                    )
            
                return subsetList }

        | set { Subsets }

    emit:

        Main = Subsets

    }