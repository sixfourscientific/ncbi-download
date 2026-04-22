
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

        tuple   val  (CoreMeta),
                path (INPUT),
                path (OPTIONAL),
                val  (Arguments)

    output:

        tuple   val  (CoreMeta),
                path ('**/*.zip'),

                emit: Main

    // MAIN

    script:

        """

        while IFS=\$'\\t' read -r ID ACCESSION; do

            echo -e "\\nProcessing \$ACCESSION (\$ID)"

            # specify archive directory
            ZIPDIR="\${ID// /_}/\${ACCESSION}"
            mkdir -p \$ZIPDIR

            ZIPFILE="\${ZIPDIR}/\${ACCESSION}.zip"

            # attempt resubmit before fail
            success=false
            attempt_max=3
            attempt_num=0

            while [ \$success = false ] && [ \$attempt_num -le \$attempt_max ]; do

                attempt_num=\$(( attempt_num + 1 ))
                
                case \$attempt_num in

                1) echo -e "\\nFetching..." ;;

                *) echo -e "\\nRetrying (attempt \$attempt_num)..." ;;

                esac

                # download assembly zip archive
                set +e
                datasets download genome \\
                    $task.ext.arguments \\
                    --filename \${ZIPFILE} \\
                    accession \${ACCESSION}
                EXITCODE1="\$?"
                set -e

                # test archive integrity
                if [ -f \$ZIPFILE ] && [ \$EXITCODE1 -eq 0 ]; then

                    set +e
                    unzip -t \${ZIPFILE}
                    EXITCODE2="\$?"
                    set -e

                    case \$EXITCODE2 in

                    0) 
                        echo -e "Done.\\n"

                        success=true ;;

                    *) 
                        echo -e "\\nERROR ~ Testing archive failed; \$ACCESSION (\$ID)"

                        rm \$ZIPFILE ;;

                    esac

                fi

                if [ \$success = false ]; then

                    echo -e "\\nERROR ~ Download failed (Attempt \$attempt_num of \$attempt_max); \$ACCESSION (\$ID)" 

                    case \$attempt_num in

                    \$attempt_max) 

                        echo -e "\\nINFO ~ Download attempts exceeded; \$ACCESSION (\$ID)\\n"
                        
                        exit 1 ;;

                    *) sleep 2 ;;

                    esac
                fi

                done

        done < $INPUT

        """

    }

/* 

VERSION: X.X

HELP

*/
