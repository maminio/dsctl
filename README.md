# Data Science Lab Cluster Control

> This configuration is only valid on `fs.dslc.liacs.nl`.


## Cluster access

To access `fs.dslc.liacs.nl` you must first be logged into one of the universities services and ssh into the cluster from a secure environment. 
```
# i.e. ssh to silver server 
ssh <YOUR_STUDENT_NUMBER>@silver.liacs.nl  
# Example: ssh s258562@silver.liacs.nl

# ssh to ds cluster from silver server
ssh fs.dslc.liacs.nl

```


## DS-ctl
This repository contains a `dsctl.sh` file which can simply setup a standalone Spark cluster. 
You can easily clone this repo in the root of your cluster's master node by running: 
```
git clone https://github.com/maminio/dsctl

```

**To view all the available commands run:**
```
bash ./dsctl.sh -h
Usage: ./dsctl.sh [option]
init                      Setup all initial software and packages.
python_setup              Setup all initial software and packages.
start_master              Start master node of the cluster
start_worker              Start one worker, to start all workers at once please run start_workers
start_workers             Start all worker nodes
start                     Start both the master and worker nodes.
stop_all                  Stop all current nodes.
```

## Spark Cluster setup

Navigate to `dsctl` folder and run the below command to initialize all the prerequizite packages and softwares.
```
bash ./dsctl.sh init
```
> This command will prompt to enter your password to setup and transfer all the shared files between master and worker nodes.


## Python setup 

To work with Pyspark or using jupyter, you need to install python. 
**This file will only install `Python 3.7.4`.**

To start the installation run: 
```
bash ./dsctl.sh python_setup
```

> This command will take a while to run as it will be building python from the source.


## Starting/Stoping the Cluster

To star the cluster will the `master node` and all the available `worker node` you can simply run:
```
bash ./dsctl.sh start
```
To stop the cluster and all running nodes:

```
bash ./dsctl.sh stop_all
```

# Connecting to the cluster 

There are two options available to connect to the cluster. 
1. You can `ssh port-forward` the whole `master node` **port (8085)**. 
2. Start `Jupyter Notebook` on the cluster and only port forward the `Jupyter Notebook`. 

## Port-forward Jupyter Notebook

1. SSH to `fs.dslc.liacs.nl`
2. Install `Jupyter`
```
python -m pip install jupyter
```
3. Run jupyter notebook
```
python -m jupyter notebook --no-browser --port=9995
```
4. From your local terminal ssh-port-forward to the cluster
```
local: 
ssh -L 9995:localhost:2366 <YOUR_STDENT_NUMBER>@silver.liacs.nl  
ssh -4 -N -L 2366:fs.dslc.liacs.nl:9995 <YOUR_STDENT_NUMBER>@fs.dslc.liacs.nl
```
5. Open jupyter on your local browser: `localhost:9995`

## Port-forward Master Node

1. Open a terminal and ssh-port-forward to `silver`.
```
ssh -L 8085:localhost:2348 <YOUR_STDENT_NUMBER>@silver.liacs.nl  
```
2. SSH port-forward from `silver` to `fs.dslc.liacs.nl`

```
ssh -4 -N -L 2348:fs.dslc.liacs.nl:8085 <YOUR_STDENT_NUMBER>@fs.dslc.liacs.nl
```
3. Connect your local `Jupyter Notebook` to the cluster
```
from pyspark import SparkContext
from pyspark.sql import SQLContext
import warnings
try:
    sc = SparkContext(appName="SDDM", master='spark://localhost:8085')
except ValueError:
    warnings.warn("SparkContext already exists in this scope")
```






