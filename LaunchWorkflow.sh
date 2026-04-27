#!/usr/bin/env bash

# SETUP 

# specify help message
showHelp() {

cat << EOF  
Usage: $(basename $LAUNCHER) -s <system> -p <parameters> -i <inputs> -x <branch> [-r <launch_directory> -a <archive_directory> -c -t -q SUPPLEMENTARY=NAME]

-h     Display help.

-s     Specify nextflow config system profile name

-p     Specify nextflow params-file basename

-i     Specify path to primary inputs list (e.g. samples)

-x     Specify workflow branches to execute

-r     Specify previous directory to resume pipeline from

-c     Clean up cache and work directories

-t     Test run

$1

EOF

exit 0 

}

exec() {

eval "$1"

case "$?" in

    0)  ;;

    ?)  # ERROR
        echo -e "\n>>> ResumeDir: $(basename $NF_LAUNCH_SUBDIR)"

        echo -e "\n>>> ArchiveDir: $(dirname $NF_LAUNCH_SUBDIR)"

        echo -e "\nError ~ Execution aborted with exit code $?.\n"

        exit 0 ;; 

esac

}

# parse arguments

REPO_DIR=$(dirname $(realpath "$0"))

PARAMETERS="default"
BRANCHES="none"
INPUTS='none'
ARCHIVE="$REPO_DIR/archive"

while getopts ':hs:p:i:x:a:r:ct' OPT; do

    case "$OPT" in

        h) showHelp "Launch script to run & resume nextflow pipelines" ;;

        s) SYSTEM="$OPTARG" ;;

        p) PARAMETERS="$OPTARG" ;;

        i) INPUTS="$OPTARG" ;;

        x) BRANCHES="$OPTARG" ;;

        a) ARCHIVE="$OPTARG" ;;

        r) DIR2RESUME="$OPTARG" ;;

        c) CLEAN=1 ;;

        t) TEST=1 ;;

        ?) showHelp "Error ~ Incorrect arguments provided" ;;
    
    esac

done; shift "$(($OPTIND -1))"


# RESUME PARAMETERS

if [ -z "$DIR2RESUME" ]; then

    echo -e "\n*** Starting New Run ***"

else
    
    echo -e "\n*** Resuming Old Run ***"

    IFS=_ read -r PREFIX SYSTEM PARAMETERS DATE TIME <<< "$DIR2RESUME"

    echo -e "\n*** Previous Parameters Inferred ***"

fi


# SPECIFY PIPELINE STRUCTURE

LAUNCHER=$(readlink -f $0)

WORKDIR=$(dirname $LAUNCHER)


if [ -z "$ARCHIVE" ]; then

    ARCHIVE="$WORKDIR"

else 
    
    if [ ! -d $ARCHIVE ]; then

        ARCHIVEBASE="$(basename $ARCHIVE)" 
        ARCHIVEDIR="$(dirname $ARCHIVE)" 

        if [ -d "$ARCHIVEDIR" ]; then

            echo -e "\nCreating archive subdirectory \"$ARCHIVEBASE\""

            mkdir -p "$ARCHIVE"

        else

            echo -e "\nNeither archive directory nor parent directory found;\nCheck path \"$ARCHIVE\""

            exit 0

        fi

    fi

fi

PIPEDIR="$WORKDIR/pipeline"

WORKFLOW="$PIPEDIR/stem.nf"

CONFIG="$PIPEDIR/nextflow.config"

PARAMETER_DIR="$PIPEDIR/params"


# CHECK SYSTEM

if [ -z $SYSTEM ]; then # no profile provided

    showHelp "Error ~ System not provided: Check config file for available system profiles; $CONFIG"

fi


# CHECK PARAMETERS; TBC

PARAMETER_FILE=($(ls -1 $PARAMETER_DIR/$PARAMETERS.{json,yml,yaml} 2> /dev/null)) # list parameters found; error suppressed

if [ -z $PARAMETER_FILE ]; then # no parameters provided

    showHelp "Error ~ Parameters not found: Check parameter directory for available files; $PARAMETER_DIR"

elif [ "${#PARAMETER_FILE[@]}" -gt 1 ]; then # multiple parameter formats found

    showHelp "Error ~ Multiple parameters found: *** TBC *** ; $(printf "\n\n\t> %s" "${PARAMETER_FILE[@]}")"

fi

# CHECK INPUTS

INPUTS=$(readlink -f "$INPUTS")

if [ ! -f "$INPUTS" ]; then
    showHelp "Error ~ Input not found: Check input file path"
    
fi

SUPPLEMENTARY=''

for ARGUMENT in "$@"; do

    IFS='=' read -r INFO TAG <<< "$ARGUMENT"

    INFO=$(readlink -f "$INFO")

    if [ ! -f "$INFO" ]; then
        showHelp "Error ~ Supplementary input not found: Check input file path"
    fi

    SUPPLEMENTARY="${SUPPLEMENTARY:+$SUPPLEMENTARY }$ARGUMENT"
  
done


# TEST MODE

if [ $TEST ]; then

    #DRYRUN=".DRYRUN"
    #STUB="-stub"
    PREVIEW='-preview'

fi


# CHECK PREVIOUS LAUNCH

# specify launch directory
DIR2START="launch_${SYSTEM}_${PARAMETERS}"

#NF_LAUNCH_DIR_NEW="$WORKDIR/$DIR2START"
NF_LAUNCH_DIR_NEW="$ARCHIVE/$DIR2START"

#NF_LAUNCH_DIR_OLD="$WORKDIR/$DIR2RESUME"
NF_LAUNCH_DIR_OLD="$ARCHIVE/$DIR2RESUME"

if [ -z $DIR2RESUME ]; then

    DATE_TIME=$(date '+%Y.%m.%d_%H.%M.%S') # get current datetime
    
    NF_LAUNCH_SUBDIR="${NF_LAUNCH_DIR_NEW}_${DATE_TIME}${DRYRUN}" # label launch directory

else

    if [ ! -d $NF_LAUNCH_DIR_OLD ]; then # previous launch directory not found

        showHelp "Error ~ Directory not found: Check working directory for available options; $WORKDIR"
            
    elif [[ ! "$NF_LAUNCH_DIR_OLD" == ${NF_LAUNCH_DIR_NEW}_* ]]; then # previous launch directory format unexpected
        echo "- $NF_LAUNCH_DIR_NEW"
        echo "-- $NF_LAUNCH_DIR_OLD"
        showHelp "Error ~ Directory format unexpected: Check prefix matches \"$(basename $NF_LAUNCH_DIR_NEW)\"; $NF_LAUNCH_DIR_OLD"
        
    else
    
        NF_LAUNCH_SUBDIR=$NF_LAUNCH_DIR_OLD # specify relevant launch directory
    
        RESUME="-resume"

    fi # checks; RESUME

fi # mode; NEW|RESUME



# PREPARE LAUNCH

# create launch directory
exec "mkdir -p $NF_LAUNCH_SUBDIR"

# specify pipeline execution command
IFS='' read -r -d '' LAUNCH_COMMAND << EOF
    nextflow \\
        -C $CONFIG \\
        run $WORKFLOW \\
        $RESUME \\
        $STUB \\
        $PREVIEW \\
        -profile $SYSTEM \\
        -params-file $PARAMETER_FILE \\
        --execute $BRANCHES \\
        --inputs $INPUTS \\
        --supplementary "$SUPPLEMENTARY"
EOF

LAUNCH_COMMAND=$(grep -v '^\s*\\' <<< "$LAUNCH_COMMAND")

echo -e "\nEXECUTING:\n\n$LAUNCH_COMMAND\n"



# LAUNCH

# move to launch directory
exec "cd $NF_LAUNCH_SUBDIR"

echo -e "\n>>> LaunchDir: $(basename $(pwd))\n"

# launch pipeline
exec "$LAUNCH_COMMAND"


# PLOT DAG

DOT=$(which dot) # check graphviz installed

DAG=$(ls -t logs/*/*.dot 2> /dev/null | head -n 1) # find latest dag; error suppressed
#DAG=$(ls -t logs/*/dag.html 2> /dev/null | head -n 1) # find latest dag; error suppressed

if [ -z $DOT ] || [ -z $DAG ]; then # DAG dependencies missing
#if [ -z $DAG ]; then # DAG dependencies missing

    echo -e "\n*** Unable to plot DAG ***"

else # Graphviz installed & DAG found

    echo -e "\n>>> Generating DAG..."

    exec "dot -Tpdf $DAG -O" # execute graphviz
    
    exec "cp ${DAG}.pdf $WORKDIR/dag_latest.pdf" # publish latest dag
#    exec "cp $DAG $WORKDIR/dag_latest.html" # publish latest dag

fi # checks; plot


# CLEAN UP

if [ $CLEAN ]; then
    
    echo -e "\n>>> Cleaning up workflow directory..."

    exec "nextflow clean -force -keep-logs -quiet -but none" # execute clean

    exec "tar -cf workClean.tar work" # archive .command files

    exec "rm -r work" # remove cleaned work directory

    # remove singularity cache directory layers; ~/.singularity/cache
    # singularity cache clean -f

    # remove nextflow singularity cache images; cacheDir
    # rm -r ./singularity

fi # checks; clean

echo -e "\n>>> ResultDir: $(basename $NF_LAUNCH_SUBDIR)"

echo -e "\n>>> ArchiveDir: $(dirname $NF_LAUNCH_SUBDIR)"

echo -e "\nDONE\n"
