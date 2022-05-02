FROM openvino/ubuntu20_dev:2022.1.0

WORKDIR /home/openvino

# Download caffe model and convert to OpenVINO IR
RUN omz_downloader --name mobilenet-ssd && \
    mo --input_model public/mobilenet-ssd/mobilenet-ssd.caffemodel --data_type FP32

# Download test images data
RUN mkdir test_images && \
    curl -o test_images/dog.jpg https://storage.openvinotoolkit.org/data/test_data/images/dog.jpg && \
    curl -o test_images/person_detection.png https://storage.openvinotoolkit.org/data/test_data/images/person_detection.png && \
    curl -o test_images/cat.jpg https://storage.openvinotoolkit.org/data/test_data/images/cat.jpg && \
    curl -o test_images/car1.png https://storage.openvinotoolkit.org/data/test_data/images/car.png && \
    curl -o test_images/car2.bmp https://storage.openvinotoolkit.org/data/test_data/images/car_1.bmp

ENTRYPOINT benchmark_app -m mobilenet-ssd.xml -i test_images -t 20 -d CPU -stream_output -hint throughput

