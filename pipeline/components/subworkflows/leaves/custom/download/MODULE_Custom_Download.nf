
include { 
    formatArguments as formatArguments;
    } from "$params.importMap.functions/core/Utils"

process MODULE {

    // SETUP

    tag "$CoreMeta.RUN"

    label workflow.profile in params.profileLabels 
        ? workflow.profile.toUpperCase()
        : 'DEFAULT'

    // EXTRA

    ext version : {

            def version = CoreMeta.STAGING.VERSION

            return version },

        arguments: { 

            def arguments = formatArguments( Arguments, '\s', '            ')

            return arguments },

        outFile: { 

            def outFile = "OUTPUT.EXT"

            return outFile }


    // TAKE & EMIT

    input:

        tuple   val (CoreMeta),
                val (sourceURL),
                val (Arguments)

    output:

        tuple   val  (CoreMeta),
                path ('*.{gz,json}'),

                emit: Main

    // MAIN

    script:

        // SETUP

        def fileName  = "${file(sourceURL).getName()}"
        def localMD5  = "local.md5"
        def sourceMD5 = "source.md5"

        """
        # download taxonomy data

        wget -q $sourceURL

        # check wget status
        case "\$?" in
            0) echo "Download: Complete" ;;
            ?) echo "Download: Error (\$?)" ;;
        esac

        # check corresponding md5 for gz files
        if [[ "$sourceURL" == *.gz ]]; then

            # download source md5sum
            wget -q ${sourceURL}.md5

            # extract hash & record in file
            cat *.md5 | cut -d ' ' -f 1 > $sourceMD5

            # calculate local md5sum, extract hash & record in file
            md5sum $fileName | cut -d ' ' -f 1 > $localMD5

            # compare local & source md5sums
            cmp $sourceMD5 $localMD5

            # check cmp status
            case "\$?" in
                0) echo "MD5: Match" ;;
                ?) echo "MD5: Differ (\$?)" ;;
            esac

        fi
        """

    }

/* 

VERSION: X.X

HELP

*/
