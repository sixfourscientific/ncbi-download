// IMPORT

include { 
    parseConfig as parseConfig;
    } from "$params.importMap.functions/core/Files"

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

    emit:

        Main = Channel.from(Configs)

    }