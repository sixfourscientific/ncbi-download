
// BRANCH

// IMPORT

include { 
    viewMeta as viewMeta;
    getGroupKey as getGroupKey;
    groupOutputs as groupOutputs;
    } from "$params.importMap.functions/core/Utils"

include { 
    Config_Parse as ParseConfig;
    } from "${params.importMap.subworkflows}/core/Config_Parse"

include {
    STAGING as DownloadCustom;
    } from "${params.importMap.subworkflows}/leaves/custom/download/STAGING_Custom_Download.nf"

////LEAF_IMPORT////


workflow SUBWORKFLOW {


    take: 

        Parameters

        Inputs


    main:

        ////LEAF_START////

        // CUSTOM DOWNLOAD
        
        ConfigDownloadCustom = ParseConfig( Parameters, [software: 'CUSTOM', command: 'DOWNLOAD', branch: 'TAXONOMY'] )
        
        DownloadCustom( Inputs, ConfigDownloadCustom )

        ////LEAF_PARSE_RUN////

        | map { coreMeta ->

            def groupKey = getGroupKey( coreMeta.group ?: 'forced', 'group')

            return [
                groupKey,
                coreMeta, 
                ] }

        | groupTuple ( by:0 )

        | map { groupKey, coreMetaGroup ->

            def groupTag = groupKey

            def coreMetaSorted = coreMetaGroup
                .sort{ first, second -> first['name'] <=> second['name'] }

            // group info for non standard coreMeta fields 
            def coreMetaNew = [
                type : groupKey,
                url  : null,
                ]

            def coreMetaTemplate = coreMetaSorted
                .first() + coreMetaNew

            // group 1
            def (SOFTWARE1, COMMAND1, BRANCH1, type1) = [ "CUSTOM", "DOWNLOAD", "TAXONOMY", "main" ]
            def outputList1 = coreMetaSorted.OUTPUTS[(SOFTWARE1)][(COMMAND1)][(BRANCH1)][(type1)]

            def outputMeta1 = [
                (SOFTWARE1) : [
                    (COMMAND1) : [ 
                        (BRANCH1): [
                            (type1) : outputList1,
                            ] ] ],
                                ]

            def groupMeta1 = groupOutputs( coreMetaTemplate, outputMeta1, groupTag )

            // group n ...
            
            return groupMeta1 }

        | set { Processed }


    emit :

        Main = Processed

    }
