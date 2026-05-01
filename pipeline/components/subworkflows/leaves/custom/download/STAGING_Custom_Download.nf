
// STAGING

// IMPORT

include { 
    preStage  as preStage;
    postStage as postStage;
    } from "$params.importMap.functions/core/Utils"

include { 
    MODULE as Run;
    } from "${params.importMap.subworkflows}/leaves/custom/download/MODULE_Custom_Download.nf"

workflow STAGING {

    take: 

        Inputs

        Config

    main:

        Inputs

        | combine ( Config )


        // PRE-STAGE

                | map { coreMeta, configMeta ->

                    def coreMetaNew  = preStage( 
                        coreMeta     : coreMeta, 
                        configMeta   : configMeta,
                        tagDelimiter : null,
                        tagDefault   : null,                        
                        )
                        
                    return coreMetaNew }


        // STAGE

                | map { coreMeta ->

                    return [
                        coreMeta,
                        coreMeta.url,
                        coreMeta.STAGING.ARGS,
                        ] }


        | Run


         // POST-STAGE

                | map { coreMeta, output ->

                    def updateList = [
                        [['CUSTOM','DOWNLOAD', coreMeta.STAGING.BRANCH, 'main'],  output],
                        ]

                    def coreMetaNew = postStage( 
                        coreMeta     : coreMeta,
                        updateList   : updateList,
                        tagDelimiter : null,
                        tagDefault   : null,
                        )

                    return coreMetaNew }


        | set { Processed }


    emit:

        Main = Processed

    }
