
// STAGING

// IMPORT

include { 
    preStage  as preStage;
    postStage as postStage;
    } from "../../../../functions/core/Utils"

include { 
    MODULE as Run;
    } from "./MODULE_Datasets_Download.nf"

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

                    def skipOptional = !coreMeta.optional || !coreMeta.STAGING.ARGS.containsKey('--optional')

                    def optionalFile  = file( !skipOptional ? coreMeta.optional : coreMeta.dummy )

                    return [
                        coreMeta,
                        coreMeta.BATCH.FILE,
                        optionalFile,
                        coreMeta.STAGING.ARGS,
                        ] }


        | Run


         // POST-STAGE

                | map { coreMeta, output ->

                    def updateList = [
                        [['DATASETS', 'DOWNLOAD', coreMeta.STAGING.BRANCH, 'main'],  output],
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

        Processed

    }
