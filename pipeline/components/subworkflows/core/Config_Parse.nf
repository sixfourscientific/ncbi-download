// IMPORT

include { 
    parseConfig as parseConfig;
    } from "../../functions/core/Files"

workflow Config_Parse {

    take: 
    
        Parameters

        PathMeta

    main:

        def Configs = parseConfig( 
            parameters : Parameters,
            software   : PathMeta.software, 
            command    : PathMeta.command, 
            branch     : PathMeta.branch,
            )

        Parsed = channel.from(Configs)

    emit:

        Parsed

    }