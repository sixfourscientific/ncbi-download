
// IMPORT

include { 
    parseInfo as parseInfo;
    } from "$params.importMap.functions/core/Files"

workflow Info_Parse {

    take: 
    
        Input

    main:

        def Info = parseInfo(
            input: Input,
            )

    emit:

        Main = Channel.from(Info)

    }