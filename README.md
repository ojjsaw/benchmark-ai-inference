Repo to perfor experiments with benchmark_app OpenVINO v2022.1

## local install & activate
```
python3 -m pip install --user virtualenv 
python3 -m venv openvino_env
source openvino_env/bin/activate
python -m pip install --upgrade pip
```

## install ov local
```
pip install openvino-dev[caffe]
```

## download & convert model
```
omz_downloader --name mobilenet-ssd
mo --input_model public/mobilenet-ssd/mobilenet-ssd.caffemodel --data_type FP32
```

## download test images
```
mkdir test_images && \
curl -o test_images/dog.jpg https://storage.openvinotoolkit.org/data/test_data/images/dog.jpg && \
curl -o test_images/person_detection.png https://storage.openvinotoolkit.org/data/test_data/images/person_detection.png && \
curl -o test_images/cat.jpg https://storage.openvinotoolkit.org/data/test_data/images/cat.jpg && \
curl -o test_images/car1.png https://storage.openvinotoolkit.org/data/test_data/images/car.png && \
curl -o test_images/car2.bmp https://storage.openvinotoolkit.org/data/test_data/images/car_1.bmp
```

## run profiling
```
benchmark_app -m mobilenet-ssd.xml -i test_images -t 20 -d CPU -stream_output -hint throughput
```

## docker commands
```
docker build -t profiling:latest .
docker run --rm profiling:latest
```