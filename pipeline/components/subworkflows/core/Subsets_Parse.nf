
// IMPORT

include { 
    parseSubsets as parseSubsets;
    writeSubset  as writeSubset;
    groupSubset  as groupSubset;
    } from "../../functions/core/Files"


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

                    def ( fileName, fileText ) = writeSubset(
                        batch   : subsetMeta.BATCH,
                        grouped : subsetMeta.GROUPED,
                        )   

                    return [ fileName, fileText, ] }

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

                | map { _groupID, infoGroup ->

                    def subsetMetaNew = groupSubset(
                        grouped : infoGroup,
                        )

                    return subsetMetaNew }
        
        | set { Processed }



    emit:

       Processed

    }