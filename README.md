# Benchmark optimized AI Inference on Intel CPU
Repo to perform evaluation of AI inference workload consistantly across environments.

1. **Local:** Host vs Containerized
2. **DevCloud:** Bare-Metal vs Container Playground
3. TBD (stretch): Python vs CPP - eg. comparison with published benchmark results

## Todo
- [x] Identify initial common: container - dockerfile, host - tool, input, model, etc.
- [ ] Tweak benchmark_app args for final evaluation
- [ ] Generate functional port for DevCloud with minimal changes
- [ ] Ensure identical containerized version with minimal changes
- [ ] Run on DevCloud Bare-Metal (same hw)
- [ ] Run on DevCloud Container Playground (same hw)
- [ ] Run on Local host
- [ ] Run on local machine container

# Results
| Environment/Throughput | OS | Platform | #1 FPS | #2 FPS | #3 FPS | Median FPS
| :---- | :---: | :---: | :---: | :---: | :---: | :---: |
| Local Host | ? | ? | ? | ? | ? |? |
| Local Container | ? | ? | ? | ? | ? |? |
| DevCloud Bare-Metal | ? | 11th Gen Intel(R) Core(TM) i7-1185G7E @ 2.80GHz, 16GB RAM | 107.01 | 104.83 | 109.20 | 107 |
| DevCloud Container Playground | ? | 11th Gen Intel(R) Core(TM) i7-1185GRE @ 2.80GHz, 16GB RAM | 94.39 | 96.32 | 98.20 | 96 |

# Initial Experiments functional code

## Local install & activate
```
python3 -m pip install --user virtualenv 
python3 -m venv openvino_env
source openvino_env/bin/activate
python -m pip install --upgrade pip
```

## Install ov local
```
pip install openvino-dev[caffe]
```

## Download & convert model
```
omz_downloader --name mobilenet-ssd
omz_converter --name mobilenet-ssd --precisions FP16
```

## Download test images
```
mkdir test_images && \
curl -o test_images/dog.jpg https://storage.openvinotoolkit.org/data/test_data/images/dog.jpg && \
curl -o test_images/person_detection.png https://storage.openvinotoolkit.org/data/test_data/images/person_detection.png && \
curl -o test_images/cat.jpg https://storage.openvinotoolkit.org/data/test_data/images/cat.jpg && \
curl -o test_images/car1.png https://storage.openvinotoolkit.org/data/test_data/images/car.png && \
curl -o test_images/car2.bmp https://storage.openvinotoolkit.org/data/test_data/images/car_1.bmp
```

## Run profiling
```
benchmark_app -m public/mobilenet-ssd/FP16/mobilenet-ssd.xml -i test_images -t 20 -d CPU -stream_output -hint throughput
```

## Docker commands
```
docker build -t profiling:latest .
docker run --rm profiling:latest
```

## DevCloud job
```
qsub -l nodes=1:idc045 job.sh
```

https://ark.intel.com/content/www/us/en/ark/compare.html?productIds=208082,208076
