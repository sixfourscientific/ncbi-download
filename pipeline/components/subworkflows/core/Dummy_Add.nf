
// IMPORT

workflow Dummy_Add {

    take: 
    
        Input

        Additional

    main:

        def entry = Additional.entrySet().first()

        def Dummy = channel.from('')
            .collectFile(
                name : entry.value,
                )

        Input
        
            | combine ( Dummy )

            | map { coreMeta, optionalPath ->
                
                def coreMetaNew = coreMeta + [
                    (entry.key) : optionalPath,
                    ]
                
                return coreMetaNew }

            | set{ Processed }


    emit:

        Processed

    }