# Graylog2 Dockerfile

This repository contains **Dockerfile** of [Graylog2](http://graylog2.org/)
for [Docker](https://www.docker.com/)'s [automated build](https://registry.hub.docker.com/u/himedia/graylog2/)
published to the public [Docker Hub Registry](https://registry.hub.docker.com/).

Specifically, contains:

* [Graylog2 server](http://graylog2.org/download)
* [Graylog2 web](http://graylog2.org/download)
* [MongoDB](http://www.mongodb.org/)

Need external [ElasticSearch](http://www.elasticsearch.org/) instance.


## Table of Contents

  * [Why this Docker?](#why-this-docker)
  * [Installation](#installation)
  * [Usage](#usage)
  * [Persisting data](#persisting-data)
  * [Graylog2 web: get started](#graylog2-web-get-started)
  * [Send logs from Symfony2 to Graylog2 server](#send-logs-from-symfony2-to-graylog2-server)


## Why this Docker?

Both [Kibana](http://www.elasticsearch.org/overview/kibana/) and Graylog2 are great tools for real time data analytics.
We wanted to test each product with **a unique** ElasticSearch instance:

* All logs are sent to Graylog2 server
* Graylog2 server sends logs into ElasticSearch
* Both Kibana and Graylog2 web fetch same data from ElasticSearch

![Big picture](https://raw.githubusercontent.com/Hi-Media/docker-graylog2/master/img/big_picture.png)


## Installation

1. Install [Docker](https://www.docker.com/).

2. Download automated build from public [Docker Hub Registry](https://registry.hub.docker.com/):

    ``` bash
    $ docker pull arcus/kibana
    $ docker pull himedia/elasticsearch
    $ docker pull himedia/graylog2
    ```

    **Alternatively**, you can build an image from Dockerfile:

    ```bash
    $ docker build -t="himedia/graylog2" github.com/Hi-Media/docker-elasticsearch
    $ docker build -t="himedia/graylog2" github.com/Hi-Media/docker-graylog2
    ```


## Usage

Launch all 3 Docker containers:

``` bash
$ ./graylog2-kibana-run.sh
```

Or manually:

```bash
$ ES_ID=$(docker run -d -p 9200:9200 -p 9300:9300 himedia/elasticsearch)
$ ES_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${ES_ID})

$ docker run -d -p 8080:80 -e "ES_HOST=localhost" -e "ES_PORT=9200" arcus/kibana

$ docker run -d -p 9000:9000 -p 12201:12201 -p 12201:12201/udp -p 12900:12900 -p 27017:27017 -p 28017:28017 \
    -e "ES_CLUSTER_NAME=graylog" -e "ES_CLUSTER_HOSTS=$ES_IP:9300" himedia/graylog2
```

URLs:

* ElasticSearch: `http://localhost:9200/_cluster/health?pretty=true`
* Kibana: `http://localhost:8080/index.html#/dashboard/file/default.json`
* MongoDB: `http://localhost:28017/`
* Graylog2 web, *after few seconds* (admin/admin): `http://localhost:9000/`


## Persisting data

* Logs sent to ElasticSearch via Graylog2 server are stored into `/data` [volume](https://docs.docker.com/userguide/dockervolumes/).
* Kibana's dashboards are saved into ElasticSearch
* Graylog2's dashboards are save into MongoDB, on the same container, into `/var/lib/mongodb` volume.

Mounting data directories:

``` bash
$ ./graylog2-kibana-run.sh --es-data=<host-dir> --mongodb-data=<host-dir>
```


## Graylog2 web: get started

First steps are not trivial…

#### Configure inputs

1. ➟ `System` ➟ `Inputs` ➟ select `GELF TCP` as input type ➟ click on `Launch new input`
➟ port 12201, bind address 0.0.0.0 ➟ click on `Launch`

    ![Inputs](https://raw.githubusercontent.com/Hi-Media/docker-graylog2/master/img/graylog2_web_input_gelf_tcp.png)

2. Same with `GELF UDP` as input type

#### Configure streams

1. ➟ `Streams` ➟ click on `Create stream` ➟ fill title and click on `Create stream and continue`

2. click on `Add stream rule` ➟ Field: "source", Type: "match exactly", Value "example.org"
➟ click on `Save` ➟ click on `I'm done!`

    ![Inputs](https://raw.githubusercontent.com/Hi-Media/docker-graylog2/master/img/graylog2_web_stream.png)

3. click on `Action` ➟ `Resume this stream`

    ![Inputs](https://raw.githubusercontent.com/Hi-Media/docker-graylog2/master/img/graylog2_web_stream_resume.png)

#### Configure alerts

1. click on `Action` ➟ `Manage alerts` ➟ select `Message count condition` and click on `Configure new alert condition`

    ![Inputs](https://raw.githubusercontent.com/Hi-Media/docker-graylog2/master/img/graylog2_web_stream_manage_alerts.png)

2. Fill "New alert condition" form, then click on `Add alert condition`:

    ![Inputs](https://raw.githubusercontent.com/Hi-Media/docker-graylog2/master/img/graylog2_web_stream_new_alert.png)

3. Configure Alert receivers filling `Email address` ➟ click on `Subscribe` ➟ click on `Send test alert`

    ![Inputs](https://raw.githubusercontent.com/Hi-Media/docker-graylog2/master/img/graylog2_web_stream_alert_dummy_mail_sent.png)

#### Test

On host:

* TCP test:

    ```bash
    $ echo -e '{"version": "1.1","host":"example.org","short_message":"A short message that helps you identify what is going on","full_message":"Backtrace here\n\nmore stuff","level":1,"_user_id":9001,"_some_info":"foo","_some_env_var":"bar"}\0' | nc -w 1 127.0.0.1 12201
    ```

* UDP test:

    ```bash
    $ echo '{"version": "1.1","host":"example.org","short_message":"A short message that helps you identify what is going on","full_message":"Backtrace here\n\nmore stuff","level":1,"_user_id":9001,"_some_info":"foo","_some_env_var":"bar"}' | nc -w 1 -u 127.0.0.1 12201
    ```

Messages must appear on Graylog2 web. Click on magnifying glass if needed. Mail must have been sent.


## Send logs from [Symfony2](http://symfony.com/) to Graylog2 server

Add following to `composer.json`:

```json
"graylog2/gelf-php": "dev-master"
```

Then:

```bash
$ composer update graylog2/gelf-php
```

In `config.yml`:

```yml
monolog:
    handlers:
        main:
            type:      gelf
            publisher: { hostname: 127.0.0.1, port: 12201 }
```

Finally:

```php
$this->get('logger')->notice('Hello notice…');
```

## If you are using boot2docker (VM boot2docker-vm) in Mac OSX, use below opiton to forward docker VM host ports to mac osx host

Add following to `composer.json`:

```
#!/bin/bash

PORTS=(9200,8080,27017,28017,9000)

for i in "${filecontent[@]}"
do
  VBoxManage modifyvm "boot2docker-vm" --natpf1 "tcp-port$i,tcp,,$i,,$i";
    VBoxManage modifyvm "boot2docker-vm" --natpf1 "udp-port$i,udp,,$i,,$i";
done
```
or use ```vb_ports_forwarding.sh``` bash script. 
Use ```delete_vb_ports_forwarding.sh``` to delete the forwarded ports from docker VM host to mac osx.

For running Kibana, you might also have to do ```boot2docker ssh -L 9200:localhost:9200``` to create a SSH tunnel between docker VM host and mac osx (localhost).

Use ```boot2docker ip``` to get the IP and access it via this IP.
