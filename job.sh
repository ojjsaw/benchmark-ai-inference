source /data/venv/openvino_2022.1.0.643/bin/activate

cd $PBS_O_WORKDIR

benchmark_app -m public/mobilenet-ssd/FP16/mobilenet-ssd.xml -i test_images -t 20 -d CPU -stream_output -hint throughput
