#!/bin/bash

# NAME="backup-scheduler"
NAME="$(basename "$(dirname "$PWD/file")")"
VERSION="0.3"
CONTAINER_REGISTRY="ez-registry-1.ncr.gov-ntruss.com"
ACCESS_KEY="H5cc1zdwsoOPpTlCpX1z"
SECRET_KEY="B4y5B5hewLfWVrNZpXYUGDvhPSKNT3870tNmAZ1v"
DATE=`date +'%Y%m%d-%H%M%S'`
REPORT_DIRECTORY="./security-report"

# YAML="pod-2-svc-backup-scheduler.yaml"
YAML="pod-2-svc-${NAME}.yaml"

CONFIG_PATH='/home/naru/lab/cloud_lab/conf_server/kubeconfig/psm-kubeconfig.yaml'

kube="kubectl --kubeconfig ${CONFIG_PATH}"

function registry_up() {
    
    docker rmi -f `docker images | grep $NAME | awk '{print $3}'`;
    docker login $CONTAINER_REGISTRY -u $ACCESS_KEY --password $SECRET_KEY &&
    docker build -t $NAME:$VERSION . &&
    docker image tag $NAME:$VERSION $CONTAINER_REGISTRY/$NAME:$VERSION &&
    docker push $CONTAINER_REGISTRY/$NAME:$VERSION &&
    # clear &&
    docker images | grep $NAME;
}

function do_report() {

    RESULT=$(cat $REPORT_DIRECTORY/$NAME:$VERSION-$DATE.txt | grep "Total: 0" | wc -l)
    
    # if $RESULT is 1, It's not exist vulnerablity
    if [ $RESULT = "1" ]
    then
        echo "===== RESULT : $RESULT ====="
        rm -rf $REPORT_DIRECTORY/$NAME:$VERSION-$DATE.txt
    fi

    docker rm -f `docker ps -a | grep aquasec/trivy | awk '{print $1}'`;    
    docker rmi -f `docker images | grep aquasec/trivy | awk '{print $3}'`;

}

# deploy to docker local
if [ $1 = "-ld" ]
then
    docker rmi -f `docker images | grep $NAME | awk '{print $3}'`;    
    docker build -t $NAME:$VERSION . &&
    # clear &&
    docker images | grep $NAME;
fi

# scan vulnerability to local build docker image
if [ $1 = "--scan-local" ]
then
    mkdir -p $REPORT_DIRECTORY

    docker build -t $NAME:$VERSION . &&
    # clear &&
    docker images | grep $NAME;

    docker run \
            -v /var/run/docker.sock:/var/run/docker.sock \
            aquasec/trivy \
            image $NAME:$VERSION \
            --no-progress > $REPORT_DIRECTORY/$NAME:$VERSION-$DATE.txt

    # Func : trivy report
    do_report
fi

# scan vulnerability to local filesystem jar file
if [ $1 = "--scan-local=jar" ]
then
    WORKSPACE=$2
    LOCAL_DATA_PATH=$HOME/trivy/$DATE

    mkdir -p $LOCAL_DATA_PATH/temp

    cp -r $WORKSPACE $LOCAL_DATA_PATH/temp

    echo "Analize begin -"
    echo "- "

    # echo "$LOCAL_DATA_PATH"

    docker run \
            --rm \
            -v $LOCAL_DATA_PATH/temp/:/root/.cache/ \
            aquasec/trivy -q image \
            --exit-code 1 \
            --severity CRITICAL \
            --light eclipse-temurin:17.0.9_9-jre-alpine \
            --no-progress > $LOCAL_DATA_PATH/report-$DATE.txt

    cp -r $LOCAL_DATA_PATH/report-$DATE.txt $WORKSPACE/
    rm -rf $LOCAL_DATA_PATH/temp

    echo "Report File name is report-$DATE.txt"
    echo "- Done."
fi

# deploy to docker local
if [ $1 = "--scan-ncp" ]
then
    docker pull aquasec/trivy
    docker login $CONTAINER_REGISTRY -u $ACCESS_KEY --password $SECRET_KEY
    docker run \
            -v /var/run/docker.sock:/var/run/docker.sock \
            aquasec/trivy \
            image $CONTAINER_REGISTRY/$NAME:$VERSION\
            --no-progress > $REPORT_DIRECTORY/$NAME:$VERSION-$DATE.txt

    #  Func : trivy report
    do_report
fi

# deploy to docker registry
if [ $1 = "-d" ]
then
    registry_up
fi

if [ $1 = "-k" ]
then
    $kube delete -f $YAML

    set +e

    $kube apply -f $YAML &&
    $kube get pods;
fi
