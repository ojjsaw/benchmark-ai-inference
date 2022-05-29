#!/bin/bash

############################################################
# Functions                                                #
############################################################

# External USERID, production
QSUB_NODES="idc004nc2"
PYTHON_VENV_PATH="/opt/python-env/dlwb_2022_1"
QSUB_QSVR="@v-qsvr-1"
INFER_TIME="1"

# Generic
USER_ID=$(whoami)
TARGET_DEVICE="none"
CURRENT_PATH=$(pwd)
#PYTHON_VENV_PATH=$CURRENT_PATH/"openvino_env"
#QSUB_QSVR="none"
#QSUB_NODES="idc004nc2"
PATH_TO_MODEL=$CURRENT_PATH/"public/mobilenet-ssd/FP16/mobilenet-ssd.xml"
#INFER_TIME="none"
NSTREAMS="none"
IS_ROOT_USER=true
SUBMIT_REMOTE_JOB=true

Help()
{
   # Display Help
   echo "Script to experiment and verify edge nodes on DevCloud bare-metal for openvino v2022.1 and above."
   echo
   echo "options:"
   echo "-h     Print this Help."
   echo "-u     If running as root, the id of user to submit on behalf of. | default: $USER_ID"
   echo "-d     TARGET_DEVICE option in benchmark_app. | default: $TARGET_DEVICE"
   echo "-m     PATH_TO_MODEL option in benchmark_app. | default: $PATH_TO_MODEL"
   echo "-t     TIME (in seconds) option in benchmark_app. | default: $INFER_TIME"
   echo "-s     NUMBER_STREAMS option in benchmark_app. | default: $NSTREAMS"
   echo "-v     Full Path to virtual python env with /bin/activate excluded. | default: $PYTHON_VENV_PATH"
   echo "-q     Queue server portion of qsub command e.g. @v-qsvr-1 | default: $QSUB_QSVR"
   echo "-n     Nodes portion of qsub command, ignored if -q is none for non devcloud use. | default: $QSUB_NODES"
   echo
   echo "If no model exists, activate venv & execute \"omz_downloader --name mobilenet-ssd && omz_converter --name mobilenet-ssd --precisions FP16\""
}

WriteJobFile()
{
    echo "#!/bin/bash" > job.sh
    echo "source ${PYTHON_VENV_PATH}/bin/activate" >> job.sh

    echo >> job.sh

    if [ "$SUBMIT_REMOTE_JOB" = true ]; then
        echo "cd \$PBS_O_WORKDIR" >> job.sh
    fi

    echo >> job.sh

    BENCHMARK_CMD_STRING="benchmark_app -m $PATH_TO_MODEL -b 1 -stream_output"
    if [ $INFER_TIME != "none" ]; then
        BENCHMARK_CMD_STRING+=" -t "$INFER_TIME
    fi

    if [ $TARGET_DEVICE != "none" ]; then
        BENCHMARK_CMD_STRING+=" -d "$TARGET_DEVICE
    fi

    if [ $NSTREAMS != "none" ]; then
        BENCHMARK_CMD_STRING+=" -nstreams "$NSTREAMS
    fi

    echo $BENCHMARK_CMD_STRING >> job.sh

}

WaitForFinish()
{
    # does not work for root user

    SECONDS=0
    echo "Full JobID: $1"
    IFS='.' read -r JOB_ID string <<< "$1"

    until [ -f $CURRENT_PATH/job.sh.o$JOB_ID ]
    do
        sleep 1
    done
    ELAPSED="$JOB_ID completed in $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"

    if grep -q "Dumping statistics report" "$CURRENT_PATH/job.sh.o$JOB_ID"; then
        echo "SUCCESS: $ELAPSED"
    else
        echo "FAILURE: $ELAPSED"
    fi
    exit

}

RunBenchmarkJob()
{
    # Append JOB ID to URL to get telemetry dashboard - e.g. https://devcloud.intel.com/edge/metrics/d/440161
    QSUB_CMD_STRING="qsub -l nodes=1:$QSUB_NODES -q $QSUB_QSVR $CURRENT_PATH/job.sh"

    if [ "$IS_ROOT_USER" = true ]; then
        echo "Submitting job on Devcloud from root as specified user: $USER_ID"
        echo "Executing: su --login $USER_ID --command \"$QSUB_CMD_STRING\""
        JOB_ID_FULL_STRING=$(su --login $USER_ID --command "$QSUB_CMD_STRING")
        WaitForFinish $JOB_ID_FULL_STRING
    else
        if [ "$SUBMIT_REMOTE_JOB" = true ]; then
            echo "Submitting job on Devcloud as current user: $USER_ID"
            echo "Executing: $QSUB_CMD_STRING"
            JOB_ID_FULL_STRING=$($QSUB_CMD_STRING)
            WaitForFinish $JOB_ID_FULL_STRING
        else
            echo
            echo "Invoking job locally without any submission."
            source $CURRENT_PATH/job.sh
        fi        
    fi
}

############################################################
# Main program                                             #
############################################################

################ Process the input options. ################

while getopts ":hu:d:m:t:s:v:q:n:" option; do
   case $option in
      h) Help
         exit;;
      u) USER_ID=$OPTARG;;
      d) TARGET_DEVICE=$OPTARG;;
      m) PATH_TO_MODEL=$OPTARG;;
      t) INFER_TIME=$OPTARG;;
      s) NSTREAMS=$OPTARG;;
      v) PYTHON_VENV_PATH=$OPTARG;;
      q) QSUB_QSVR=$OPTARG;;
      n) QSUB_NODES=$OPTARG;;
     \?) echo "Error: Invalid option"
         Help
         exit;;
   esac
done

echo "USER_ID=$USER_ID"
echo "TARGET_DEVICE=$TARGET_DEVICE"
echo "PYTHON_VENV_PATH=$PYTHON_VENV_PATH"
echo "QSUB_QSVR=$QSUB_QSVR"
echo "QSUB_NODES=$QSUB_NODES"
echo "PATH_TO_MODEL=$PATH_TO_MODEL"
echo "INFER_TIME=$INFER_TIME"
echo "NSTREAMS=$NSTREAMS"

if [ $(whoami) == $USER_ID ]; then
    IS_ROOT_USER=false
    if [ $QSUB_QSVR == "none" ]; then
        SUBMIT_REMOTE_JOB=false
    fi
fi

echo "IS_ROOT_USER=$IS_ROOT_USER"
echo "SUBMIT_REMOTE_JOB==$SUBMIT_REMOTE_JOB"

############# Invoke Write Job Function ################
WriteJobFile

############# Invoke Run Job Function ################
RunBenchmarkJob

