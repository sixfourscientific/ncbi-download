
// STAGING

// IMPORT

include { 
    preStage  as preStage;
    postStage as postStage;
    } from "$params.importMap.functions/core/Utils"

include { 
    MODULE as Run;
    } from "${params.importMap.subworkflows}/leaves/datasets/download/genome/batch/MODULE_Datasets_Download.nf"

workflow STAGING {

    take: 

        Inputs

        Config

    main:

        Inputs

        | combine ( Config )


        // PRE-STAGE

                | map { coreMeta, configMeta ->

                    def coreMetaNew  = preStage( coreMeta, configMeta )

                    return coreMetaNew }


        // STAGE

                | map { coreMeta ->

                    def skipOptional = !coreMeta.optional || !coreMeta.STAGING.ARGS.containsKey('--optional')

                    def optionalFile  = file( !skipOptional ? coreMeta.optional : 'optional.dummy' )

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
                        coreMeta   : coreMeta,
                        updateList : updateList,
                        )

                    return coreMetaNew }


        | set { Processed }


    emit:

        Main = Processed

    }
