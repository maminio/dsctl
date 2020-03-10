#!/usr/bin/env bash

step=1
options=("Client Container" "Server Container" "Shared Container" "Worker Container" "Storage Manager Container", "Email Service Container")
choices=""
project_root=$(cd ./ && pwd)
__file_name="run.sh"
declare -a nodes=("node01" "node02" "node04" "node04")

# This url might get outdated.
__java_url="http://download.oracle.com/otn-pub/java/jdk/8u241-b07/1f5b5a70bf22433b84d0e960903adac8/jdk-8u241-linux-x64.tar.gz"

check_requirements () {
    if ! [[ -x "$(command -v bash)" ]]
    then
      echo Error: bash is not installed.
      return 0
    fi
    if ! [[ -x "$(command -v wget)" ]]
    then
      echo Error: wget is not installed.
      return 0
    fi
    if ! [[ -x "$(command -v tar)" ]]
    then
      echo Error: tar is not installed.
      return 0
    fi
    step=$((step + 1))
    return 1
}



function help () {
  echo "" 1>&2
  echo " ${*}" 1>&2
  echo "" 1>&2
  echo "  ${__usage:-No usage available}" 1>&2
  echo "" 1>&2

  if [[ "${__helptext:-}" ]]; then
    echo " ${__helptext}" 1>&2
    echo "" 1>&2
  fi

  exit 1
}


initial_setup () {
    echo "Initializing env setup. This will take a while, go grab a coffee! (upto 10mins)"
    echo "Installing Java 1.8"
    ###################Installing JAVA###################
    wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" $__java_url -O /tmp/jdk_1.8.tar.gz
    echo "Download complete, unziping."
    echo "Setting JAVA_HOME."

    mkdir -p ~/.local/bin


    echo 'export PATH=$HOME/.local/bin/:$PATH' >>~/.bashrc
    mkdir -p ~/.local/bin/jdk_1.8
    tar xf /tmp/jdk_1.8.tar.gz -C ~/.local/bin/jdk_1.8 --strip-components=1
    JAVA_PATH='export PATH=~/.local/bin/jdk_1.8/bin:$PATH'
    if ! grep -q $JAVA_PATH ~/.bashrc; then
      echo $JAVA_PATH >>~/.bashrc
    fi

    #####################################################
    ###################Installing SPARK##################

    echo "Downloading Spark"
    wget http://apache.mirror.triple-it.nl/spark/spark-2.4.5/spark-2.4.5-bin-hadoop2.7.tgz -O /tmp/spark-2.4.5.tgz
    mkdir -p ~/.local/bin/spark
    tar xf /tmp/spark-2.4.5.tgz -C ~/.local/bin/spark --strip-components=1
    SPARK_PATH='export SPARK_HOME=$HOME/.local/bin/spark'
    SPARK_PORT='export SPARK_MASTER_PORT=8085'
    echo "Setting spark env vars"
    if ! grep -q $SPARK_PATH ~/.bashrc; then
      echo $SPARK_PATH >>~/.bashrc
      echo $SPARK_PORT >>~/.bashrc
      echo 'export SPARK_LOCAL_DIRS=$HOME/datasets' >>~/.bashrc
    fi

    #####################################################
    ###################Configuring SPARK#################
    echo "Configuring spark cluster with multi worker nodes."
    echo 'node01
    node02
    node03
    node04' > ~/.local/bin/spark/conf/slaves
    SPARK_MASTER_HOST=$(ip  -f inet a show enp2s0f0| grep inet| awk '{ print $2}' | cut -d/ -f1)
    echo 'SPARK_MASTER_HOST="'$SPARK_MASTER_HOST'"' > ~/.local/bin/spark/conf/spark-env.sh

    echo "Configuring nodes. Please enter your password."
    ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
    for node in "${nodes[@]}"
    do
        ssh-copy-id -i ~/.ssh/id_rsa.pub "$node"
    done
    #####################################################

    echo "All good. Cluster configured.\n To start up the cluster with all available node run: $__file_name start"
    echo '
        ******************** SETUP COMPLETE ********************
        Please run: source ~/.bashrc
        ********************************************************
    '
    step=$((step + 1))
}



python_setup () {
    echo "Setting up pre-req packages for python."
    wget ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz  -O /tmp/libffi-3.2.1.tar.gz
    mkdir -p ~/.local/bin/libffi
    tar xvf /tmp/libffi-3.2.1.tar.gz -C ~/.local/bin/libffi --strip-components=1
    (cd ~/.local/bin/libffi; ./configure --prefix=$HOME/.local/bin/libffi/; make; make install)

    # Installing sqlite for jupyter
    wget https://www.sqlite.org/2020/sqlite-autoconf-3310100.tar.gz -O /tmp/sqlite.tar.gz
    mkdir -p ~/.local/bin/sqlite
    tar -xf /tmp/sqlite.tar.gz -C ~/.local/bin/sqlite --strip-components=1
    (cd ~/.local/bin/sqlite; ./configure --prefix=$HOME/.local; make; make install)

    echo "Downloading python"
    wget https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tgz -O /tmp/python3.7.tgz
    mkdir -p ~/.local/bin/python3.7
    tar zxfv /tmp/python3.7.tgz -C ~/.local/bin/python3.7 --strip-components=1
    echo "Buckle up, this is going to take a while, installing python3 from source."
    (cd ~/.local/bin/python3.7; export LD_LIBRARY_PATH=$HOME/.local/bin/libffi/lib64; export LD_RUN_PATH=/$HOME/.local/bin/libffi/lib64; export PKG_CONFIG_PATH=$HOME/.local/bin/libffi/lib/pkgconfig; CPPFLAGS="-I$HOME/.local/bin/sqlite -I$HOME/.local/bin/libffi/include" LDFLAGS="-L$HOME/.local/bin/sqlite/.libs -L$HOME/.local/bin/libffi/lib64" ./configure  --prefix=$HOME/.local/bin/python3.7 --enable-loadable-sqlite-extensions CPPFLAGS="-I$HOME/.local/bin/sqlite -I$HOME/.local/bin/libffi/include" LDFLAGS="-L$HOME/.local/bin/sqlite/.libs -L$HOME/.local/bin/libffi/lib64"; LD_LIBRARY_PATH=$HOME/.local/bin/libffi/lib64 LD_RUN_PATH=/$HOME/.local/bin/libffi/lib64 PKG_CONFIG_PATH=$HOME/.local/bin/libffi/lib/pkgconfig make;  LD_LIBRARY_PATH=$HOME/.local/bin/libffi/lib64 LD_RUN_PATH=/$HOME/.local/bin/libffi/lib64  PKG_CONFIG_PATH=$HOME/.local/bin/libffi/lib/pkgconfig make install)

    # Adding python to source path.
    PYTHON_PATH='export PATH=$HOME/.local/bin/python3.7/:$PATH'
    echo $PYTHON_PATH >>~/.bashrc

    source ~/.bashrc
    # Installing pip
    wget https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py
    python /tmp/get-pip.py --user
}


start_master () {
    ~/.local/bin/spark/sbin/start-master.sh
}

start_worker () {
    ~/.local/bin/spark/sbin/start-slave.sh "${*:2}"
}

start_workers () {
    ~/.local/bin/spark/sbin/start-slaves.sh
}

start () {
    ~/.local/bin/spark/sbin/start-master.sh
    ~/.local/bin/spark/sbin/start-slaves.sh 
}

stop_all () {
    ~/.local/bin/spark/sbin/stop-all.sh
}

if [[ $1 = "-h" ]]
then
    echo "Usage: $0 [option]"
    echo "init                      Setup all initial software and packages."
    echo "python_setup              Setup all initial software and packages."
    echo "start_master              Start master node of the cluster"
    echo "start_worker              Start one worker, to start all workers at once please run start_workers"
    echo "start_workers             Start all worker nodes"
    echo "start                     Start both the master and worker nodes."
    echo "stop_all                  Stop all current nodes."
    exit 0
fi



# START CHECK PREREQUISITES
check_requirements
if [[ $1 = "" ]]
then
    echo "Usage: $0 [option]"
    echo "init                      Setup all initial software and packages."
    echo "python_setup              Setup all initial software and packages."
    echo "start_master              Start master node of the cluster"
    echo "start_worker              Start one worker, to start all workers at once please run start_workers"
    echo "start_workers             Start all worker nodes"
    echo "start                     Start both the master and worker nodes."
    echo "stop_all                  Stop all current nodes."
    exit 0
fi

# END CHECK PREREQUISITES

if [[ $1 = "init" ]]
then
    initial_setup
    wait
    exit 0
fi

if [[ $1 = "python_setup" ]]
then
    python_setup
    wait
    exit 0
fi

if [[ $1 = "start_master" ]]
then
    start_master
    wait
    exit 0
fi

if [[ $1 = "start_worker" ]]
then
    start_worker
    wait
    exit 0
fi

if [[ $1 = "start_workers" ]]
then
    start_workers
    wait
    exit 0
fi


if [[ $1 = "start" ]]
then
    start
    wait
    exit 0
fi



if [[ $1 = "stop_all" ]]
then
    stop_all
    wait
    exit 0
fi



# START SETUP
initial_setup
# END SETUP

# START PYTHON
python_setup
# END PYTHON

# START MASTER
start_master
# END MASTER

# START WORKERS
start_workers
# END WORKERS

# STOP ALL
stop_all
# END STOP ALL

wait

