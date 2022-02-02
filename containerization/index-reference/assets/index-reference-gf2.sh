#!/bin/bash -l

# Create reference sequence index and dict wrapper script


###############################################################################
#### Helper Functions ####
###############################################################################

## ****************************************************************************
## Usage description should match command line arguments defined below
usage () {
    echo "Usage: $(basename "$0")"
    echo "  --reference_sequence => Reference Sequence"
    echo "  --output => Output Directory"
    echo "  --exec_method => Execution method (singularity, docker, environment, auto)"
    echo "  --exec_init => Execution initialization command(s)"
    echo "  --help => Display this help message"
}
## ****************************************************************************

# report error code for command
safeRunCommand() {
    cmd="$@"
    eval "$cmd; "'PIPESTAT=("${PIPESTATUS[@]}")'
    for i in ${!PIPESTAT[@]}; do
        if [ ${PIPESTAT[$i]} -ne 0 ]; then
            echo "Error when executing command #${i}: '${cmd}'"
            exit ${PIPESTAT[$i]}
        fi
    done
}

# print message and exit
fail() {
    msg="$@"
    echo "${msg}"
    usage
    exit 1
}

# always report exit code
reportExit() {
    rv=$?
    echo "Exit code: ${rv}"
    exit $rv
}

trap "reportExit" EXIT

# check if string contains another string
contains() {
    string="$1"
    substring="$2"

    if test "${string#*$substring}" != "$string"; then
        return 0    # $substring is not in $string
    else
        return 1    # $substring is in $string
    fi
}



###############################################################################
## SCRIPT_DIR: directory of current script, depends on execution
## environment, which may be detectable using environment variables
###############################################################################
if [ -z "${AGAVE_JOB_ID}" ]; then
    # not an agave job
    SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
else
    echo "Agave job detected"
    SCRIPT_DIR=$(pwd)
fi
## ****************************************************************************



###############################################################################
#### Parse Command-Line Arguments ####
###############################################################################

getopt --test > /dev/null
if [ $? -ne 4 ]; then
    echo "`getopt --test` failed in this environment."
    exit 1
fi

## ****************************************************************************
## Command line options should match usage description
OPTIONS=
LONGOPTIONS=help,exec_method:,exec_init:,reference_sequence:,output:,
## ****************************************************************************

# -temporarily store output to be able to check for errors
# -e.g. use "--options" parameter by name to activate quoting/enhanced mode
# -pass arguments only via   -- "$@"   to separate them correctly
PARSED=$(\
    getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@"\
)
if [ $? -ne 0 ]; then
    # e.g. $? == 1
    #  then getopt has complained about wrong arguments to stdout
    usage
    exit 2
fi

# read getopt's output this way to handle the quoting right:
eval set -- "$PARSED"

## ****************************************************************************
## Set any defaults for command line options
EXEC_METHOD="environment"
EXEC_INIT=":"
## ****************************************************************************

## ****************************************************************************
## Handle each command line option. Lower-case variables, e.g., ${file}, only
## exist if they are set as environment variables before script execution.
## Environment variables are used by Agave. If the environment variable is not
## set, the Upper-case variable, e.g., ${FILE}, is assigned from the command
## line parameter.
while true; do
    case "$1" in
        --help)
            usage
            exit 0
            ;;
        --reference_sequence)
            if [ -z "${reference_sequence}" ]; then
                REFERENCE_SEQUENCE=$2
            else
                REFERENCE_SEQUENCE="${reference_sequence}"
            fi
            shift 2
            ;;
        --output)
            if [ -z "${output}" ]; then
                OUTPUT=$2
            else
                OUTPUT="${output}"
            fi
            shift 2
            ;;
        --exec_method)
            if [ -z "${exec_method}" ]; then
                EXEC_METHOD=$2
            else
                EXEC_METHOD="${exec_method}"
            fi
            shift 2
            ;;
        --exec_init)
            if [ -z "${exec_init}" ]; then
                EXEC_INIT=$2
            else
                EXEC_INIT="${exec_init}"
            fi
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Invalid option"
            usage
            exit 3
            ;;
    esac
done
## ****************************************************************************

## ****************************************************************************
## Log any variables passed as inputs
echo "Reference_sequence: ${REFERENCE_SEQUENCE}"
echo "Output: ${OUTPUT}"
echo "Execution Method: ${EXEC_METHOD}"
echo "Execution Initialization: ${EXEC_INIT}"
## ****************************************************************************



###############################################################################
#### Validate and Set Variables ####
###############################################################################

## ****************************************************************************
## Add app-specific logic for handling and parsing inputs and parameters

# REFERENCE_SEQUENCE input

if [ -z "${REFERENCE_SEQUENCE}" ]; then
    echo "Reference Sequence required"
    echo
    usage
    exit 1
fi
# make sure REFERENCE_SEQUENCE is staged
count=0
while [ ! -f "${REFERENCE_SEQUENCE}" ]
do
    echo "${REFERENCE_SEQUENCE} not staged, waiting..."
    sleep 1
    count=$((count+1))
    if [ $count == 10 ]; then break; fi
done
if [ ! -f "${REFERENCE_SEQUENCE}" ]; then
    echo "Reference Sequence not found: ${REFERENCE_SEQUENCE}"
    exit 1
fi
REFERENCE_SEQUENCE_FULL=$(readlink -f "${REFERENCE_SEQUENCE}")
REFERENCE_SEQUENCE_DIR=$(dirname "${REFERENCE_SEQUENCE_FULL}")
REFERENCE_SEQUENCE_BASE=$(basename "${REFERENCE_SEQUENCE_FULL}")



# OUTPUT parameter
if [ -n "${OUTPUT}" ]; then
    :
    OUTPUT_FULL=$(readlink -f "${OUTPUT}")
    OUTPUT_DIR=$(dirname "${OUTPUT_FULL}")
    OUTPUT_BASE=$(basename "${OUTPUT_FULL}")
    LOG_FULL="${OUTPUT_DIR}/_log"
    TMP_FULL="${OUTPUT_DIR}/_tmp"
else
    :
    echo "Output Directory required"
    echo
    usage
    exit 1
fi

## ****************************************************************************

## EXEC_METHOD: execution method
## Suggested possible options:
##   auto: automatically determine execution method
##   singularity: singularity image packaged with the app
##   docker: docker containers from docker-hub
##   environment: binaries available in environment path

## ****************************************************************************
## List supported execution methods for this app (space delimited)
exec_methods="singularity docker environment auto"
## ****************************************************************************

## ****************************************************************************
# make sure the specified execution method is included in list
if ! contains " ${exec_methods} " " ${EXEC_METHOD} "; then
    echo "Invalid execution method: ${EXEC_METHOD}"
    echo
    usage
    exit 1
fi
## ****************************************************************************



###############################################################################
#### App Execution Initialization ####
###############################################################################

## ****************************************************************************
## Execute any "init" commands passed to the GeneFlow CLI
CMD="${EXEC_INIT}"
echo "CMD=${CMD}"
safeRunCommand "${CMD}"
## ****************************************************************************



###############################################################################
#### Auto-Detect Execution Method ####
###############################################################################

# assign to new variable in order to auto-detect after Agave
# substitution of EXEC_METHOD
AUTO_EXEC=environment
## ****************************************************************************
## Add app-specific paths to detect the execution method.
#if [ "${EXEC_METHOD}" = "auto" ]; then
    # detect execution method
#    if command -v docker >/dev/null 2>&1; then
#        AUTO_EXEC=docker
#    elif command -v singularity >/dev/null 2>&1; then
#        AUTO_EXEC=singularity
#    elif [command -v picard >/dev/null 2>&1] && [command -v samtools >/dev/null 2>&1]; then
#        AUTO_EXEC=environment
#    else
#        echo "Valid execution method not detected"
#        echo
#        usage
#        exit 1
#    fi
#    echo "Detected Execution Method: ${AUTO_EXEC}"
#fi
## ****************************************************************************



###############################################################################
#### App Execution Preparation, Common to all Exec Methods ####
###############################################################################

## ****************************************************************************
## Add logic to prepare environment for execution
MNT=""; ARG=""; CMD0="mkdir -p ${OUTPUT_FULL} ${ARG}"; CMD="${CMD0}"; echo "CMD=${CMD}"; safeRunCommand "${CMD}";
MNT=""; ARG=""; CMD0="mkdir -p ${LOG_FULL} ${ARG}"; CMD="${CMD0}"; echo "CMD=${CMD}"; safeRunCommand "${CMD}";
## ****************************************************************************



###############################################################################
#### App Execution, Specific to each Exec Method ####
###############################################################################

## ****************************************************************************
## Add logic to execute app
## There should be one case statement for each item in $exec_methods
case "${AUTO_EXEC}" in
    #singularity)
        #MNT=""; ARG=""; CMD0="cp ${REFERENCE_SEQUENCE_FULL} ${OUTPUT_FULL}/${OUTPUT_BASE}.fasta ${ARG}"; CMD="${CMD0}"; echo "CMD=${CMD}"; safeRunCommand "${CMD}";
        #MNT=""; ARG=""; fnrun0() { echo "picard CreateSequenceDictionary" | sed 's/>/\\>/g' | sed 's/</\\</g' | sed 's/|/\\|/g'; }; RUN_FULL='picard CreateSequenceDictionary'; eval "RUN_LIST=($(fnrun0))"; RUN=${RUN_LIST[0]}; for (( ri=1; ri<${#RUN_LIST[@]}; ri++ )); do if [ "${RUN_LIST[$ri]:0:1}" = "^" ]; then RARG="${RUN_LIST[$ri]#?}"; RARG_FULL=$(readlink -f "${RARG}"); RARG_DIR=$(dirname "${RARG}"); RARG_BASE=$(basename "${RARG}"); MNT="${MNT} -B "; MNT="${MNT}\"${RARG_DIR}:/data${ri}_r\""; ARG="${ARG} \"/data${ri}_r/${RARG_BASE}\""; else ARG="${ARG} ${RUN_LIST[$ri]}"; fi; done; ARG="${ARG} R="; MNT="${MNT} -B "; MNT="${MNT}\"${OUTPUT_DIR}:/data1\""; ARG="${ARG} \"/data1/${OUTPUT_BASE}/${OUTPUT_BASE}.fasta\""; ARG="${ARG} O="; MNT="${MNT} -B "; MNT="${MNT}\"${OUTPUT_DIR}:/data2\""; ARG="${ARG} \"/data2/${OUTPUT_BASE}/${OUTPUT_BASE}.dict\""; CMD0="singularity -s exec ${MNT} docker://quay.io/biocontainers/picard:2.22.9--0 ${RUN} ${ARG}"; CMD0="${CMD0} >\"${LOG_FULL}/${OUTPUT_BASE}-picard-createsequencedictionary.stdout\""; CMD0="${CMD0} 2>\"${LOG_FULL}/${OUTPUT_BASE}-picard-createsequencedictionary.stderr\""; CMD="${CMD0}"; echo "CMD=${CMD}"; safeRunCommand "${CMD}";
        #MNT=""; ARG=""; fnrun0() { echo "samtools faidx" | sed 's/>/\\>/g' | sed 's/</\\</g' | sed 's/|/\\|/g'; }; RUN_FULL='samtools faidx'; eval "RUN_LIST=($(fnrun0))"; RUN=${RUN_LIST[0]}; for (( ri=1; ri<${#RUN_LIST[@]}; ri++ )); do if [ "${RUN_LIST[$ri]:0:1}" = "^" ]; then RARG="${RUN_LIST[$ri]#?}"; RARG_FULL=$(readlink -f "${RARG}"); RARG_DIR=$(dirname "${RARG}"); RARG_BASE=$(basename "${RARG}"); MNT="${MNT} -B "; MNT="${MNT}\"${RARG_DIR}:/data${ri}_r\""; ARG="${ARG} \"/data${ri}_r/${RARG_BASE}\""; else ARG="${ARG} ${RUN_LIST[$ri]}"; fi; done; MNT="${MNT} -B "; MNT="${MNT}\"${OUTPUT_DIR}:/data1\""; ARG="${ARG} \"/data1/${OUTPUT_BASE}/${OUTPUT_BASE}.fasta\""; CMD0="singularity -s exec ${MNT} docker://quay.io/biocontainers/samtools:1.10--h9402c20_1 ${RUN} ${ARG}"; CMD0="${CMD0} >\"${LOG_FULL}/${OUTPUT_BASE}-samtools-faidx.stdout\""; CMD0="${CMD0} 2>\"${LOG_FULL}/${OUTPUT_BASE}-samtools-faidx.stderr\""; CMD="${CMD0}"; echo "CMD=${CMD}"; safeRunCommand "${CMD}";
        #;;
    #docker)
        #MNT=""; ARG=""; CMD0="cp ${REFERENCE_SEQUENCE_FULL} ${OUTPUT_FULL}/${OUTPUT_BASE}.fasta ${ARG}"; CMD="${CMD0}"; echo "CMD=${CMD}"; safeRunCommand "${CMD}";
        #MNT=""; ARG=""; fnrun0() { echo "picard CreateSequenceDictionary" | sed 's/>/\\>/g' | sed 's/</\\</g' | sed 's/|/\\|/g'; }; RUN_FULL='picard CreateSequenceDictionary'; eval "RUN_LIST=($(fnrun0))"; RUN=${RUN_LIST[0]}; for (( ri=1; ri<${#RUN_LIST[@]}; ri++ )); do if [ "${RUN_LIST[$ri]:0:1}" = "^" ]; then RARG="${RUN_LIST[$ri]#?}"; RARG_FULL=$(readlink -f "${RARG}"); RARG_DIR=$(dirname "${RARG}"); RARG_BASE=$(basename "${RARG}"); MNT="${MNT} -v "; MNT="${MNT}\"${RARG_DIR}:/data${ri}_r\""; ARG="${ARG} \"/data${ri}_r/${RARG_BASE}\""; else ARG="${ARG} ${RUN_LIST[$ri]}"; fi; done; ARG="${ARG} R="; MNT="${MNT} -v "; MNT="${MNT}\"${OUTPUT_DIR}:/data1\""; ARG="${ARG} \"/data1/${OUTPUT_BASE}/${OUTPUT_BASE}.fasta\""; ARG="${ARG} O="; MNT="${MNT} -v "; MNT="${MNT}\"${OUTPUT_DIR}:/data2\""; ARG="${ARG} \"/data2/${OUTPUT_BASE}/${OUTPUT_BASE}.dict\""; CMD0="docker run --rm ${MNT} -u $(id -u):$(id -g) quay.io/biocontainers/picard:2.22.9--0 ${RUN} ${ARG}"; CMD0="${CMD0} >\"${LOG_FULL}/${OUTPUT_BASE}-picard-createsequencedictionary.stdout\""; CMD0="${CMD0} 2>\"${LOG_FULL}/${OUTPUT_BASE}-picard-createsequencedictionary.stderr\""; CMD="${CMD0}"; echo "CMD=${CMD}"; safeRunCommand "${CMD}";
        #MNT=""; ARG=""; fnrun0() { echo "samtools faidx" | sed 's/>/\\>/g' | sed 's/</\\</g' | sed 's/|/\\|/g'; }; RUN_FULL='samtools faidx'; eval "RUN_LIST=($(fnrun0))"; RUN=${RUN_LIST[0]}; for (( ri=1; ri<${#RUN_LIST[@]}; ri++ )); do if [ "${RUN_LIST[$ri]:0:1}" = "^" ]; then RARG="${RUN_LIST[$ri]#?}"; RARG_FULL=$(readlink -f "${RARG}"); RARG_DIR=$(dirname "${RARG}"); RARG_BASE=$(basename "${RARG}"); MNT="${MNT} -v "; MNT="${MNT}\"${RARG_DIR}:/data${ri}_r\""; ARG="${ARG} \"/data${ri}_r/${RARG_BASE}\""; else ARG="${ARG} ${RUN_LIST[$ri]}"; fi; done; MNT="${MNT} -v "; MNT="${MNT}\"${OUTPUT_DIR}:/data1\""; ARG="${ARG} \"/data1/${OUTPUT_BASE}/${OUTPUT_BASE}.fasta\""; CMD0="docker run --rm ${MNT} -u $(id -u):$(id -g) quay.io/biocontainers/samtools:1.10--h9402c20_1 ${RUN} ${ARG}"; CMD0="${CMD0} >\"${LOG_FULL}/${OUTPUT_BASE}-samtools-faidx.stdout\""; CMD0="${CMD0} 2>\"${LOG_FULL}/${OUTPUT_BASE}-samtools-faidx.stderr\""; CMD="${CMD0}"; echo "CMD=${CMD}"; safeRunCommand "${CMD}";
        #;;
    environment)
        ARG=""; CMD0="cp ${REFERENCE_SEQUENCE_FULL} ${OUTPUT_FULL}/${OUTPUT_BASE}.fasta ${ARG}"; CMD="${CMD0}"; echo "CMD=${CMD}"; safeRunCommand "${CMD}";
        ARG=""; ARG="${ARG} R="; ARG="${ARG} \"${REFERENCE_SEQUENCE_FULL}\""; ARG="${ARG} O="; ARG="${ARG} \"${OUTPUT_FULL}/${OUTPUT_BASE}.dict\""; CMD0="java -jar picard.jar CreateSequenceDictionary ${RUN} ${ARG}"; CMD0="${CMD0} >\"${LOG_FULL}/${OUTPUT_BASE}-picard-createsequencedictionary.stdout\""; CMD0="${CMD0} 2>\"${LOG_FULL}/${OUTPUT_BASE}-picard-createsequencedictionary.stderr\""; CMD="${CMD0}"; echo "CMD=${CMD}"; safeRunCommand "${CMD}";
        ARG=""; ARG="${ARG} \"${OUTPUT_FULL}/${OUTPUT_BASE}.fasta\""; CMD0="samtools faidx ${RUN} ${ARG}"; CMD0="${CMD0} >\"${LOG_FULL}/${OUTPUT_BASE}-samtools-faidx.stdout\""; CMD0="${CMD0} 2>\"${LOG_FULL}/${OUTPUT_BASE}-samtools-faidx.stderr\""; CMD="${CMD0}"; echo "CMD=${CMD}"; safeRunCommand "${CMD}";
        ;;
esac
## ****************************************************************************



###############################################################################
#### Cleanup, Common to All Exec Methods ####
###############################################################################

## ****************************************************************************
## Add logic to cleanup execution artifacts, if necessary
## ****************************************************************************
