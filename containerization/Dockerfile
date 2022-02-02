# Base image
FROM ubuntu:xenial as first


# install dependences for tools
RUN apt-get update && apt-get install -y make\
    wget \
    gcc \
    perl \
    build-essential \
    libncurses5-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-gnutls-dev \
    zlib1g-dev \
    libssl-dev \
    bzip2


# install bwa for mask-repeats
FROM first as second
RUN mkdir bwa &&\
    mkdir /data &&\
    cd bwa &&\
    wget https://github.com/lh3/bwa/releases/download/v0.7.17/bwa-0.7.17.tar.bz2 &&\
    tar -xjf bwa-0.7.17.tar.bz2 &&\
    rm bwa-0.7.17.tar.bz2 &&\
    cd bwa-0.7.17 &&\
    make


ENV PATH="${PATH}:/bwa/bwa-0.7.17"


# install mummer for bwa-index
FROM second as third
RUN cd &&\
    mkdir mummer &&\
    cd mummer &&\
    wget https://github.com/mummer4/mummer/releases/download/v4.0.0rc1/mummer-4.0.0rc1.tar.gz &&\
    tar -xvf mummer-4.0.0rc1.tar.gz &&\
    rm mummer-4.0.0rc1.tar.gz &&\
    cd mummer-4.0.0rc1 &&\
    ./configure &&\
    make &&\
    make install


# install bedtools for bwa-index
FROM third as fourth
RUN cd /usr/local/bin && \
    wget https://github.com/arq5x/bedtools2/releases/download/v2.29.2/bedtools.static.binary && \
    mv bedtools.static.binary bedtools && \
    chmod +x bedtools


# install samtools for index-reference
FROM fourth as fifth
RUN cd &&\
    mkdir samtools &&\
    cd samtools &&\
    wget https://github.com/samtools/samtools/releases/download/1.10/samtools-1.10.tar.bz2 &&\
    tar -xjf samtools-1.10.tar.bz2 &&\
    rm samtools-1.10.tar.bz2 &&\
    cd samtools-1.10 &&\
    ./configure &&\
    make &&\
    make install


# install picard for index-reference (may need to copy file to index-reference app dir)
RUN cd &&\
    mkdir picard &&\
    cd picard &&\
    wget https://github.com/broadinstitute/picard/releases/download/2.22.9/picard.jar


### Need to get geneflow as base image or copy over geneflow directory from image
FROM geneflow2:2.6.0


RUN git clone https://github.com/CDCgov/mycosnp.git &&\
    cd mycosnp &&\
    gf install-workflow --make-apps v0.22 -f -g https://github.com/cjjossart/mycosnp-bwa-reference workflows/mycosnp-bwa-reference/0.22


WORKDIR /data
