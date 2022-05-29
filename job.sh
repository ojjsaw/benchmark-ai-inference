#!/bin/bash
source /home/odsawant/github/benchmark-ai-inference/openvino_env/bin/activate

cd $PBS_O_WORKDIR

benchmark_app -m /home/odsawant/github/benchmark-ai-inference/public/mobilenet-ssd/FP16/mobilenet-ssd.xml -b 1 -stream_output
