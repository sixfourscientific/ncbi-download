
// STAGING

// IMPORT

include { 
    preStage  as preStage;
    postStage as postStage;
    } from "$params.importMap.functions/core/Utils"

include { 
    MODULE as Run;
    } from "${params.importMap.subworkflows}/leaves/datasets/summary/genome/MODULE_Datasets_Summary.nf"

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
                        coreMeta.id,
                        optionalFile,
                        coreMeta.STAGING.ARGS,
                        ] }


        | Run


         // POST-STAGE

                | map { coreMeta, output ->
                    
                    def outputMeta = [
                        DATASETS : [
                            SUMMARY : [ 
                                (coreMeta.STAGING.BRANCH): [
                                    main : output,
                                    ] ] ] ]

                    def coreMetaNew = postStage( coreMeta, outputMeta )

                    return coreMetaNew }


        | set { Processed }


    emit:

        Main = Processed

    }
