
// IMPORT

include { 
    parseInfo as parseInfo;
    } from "../../functions/core/Files"

workflow Info_Parse {

    take: 
    
        Input

    main:

        def Info = parseInfo(
            input: Input,
            )

        Parsed = channel.from(Info)

    emit:

        Parsed

    }