# Approach to Containerizing MycoSNP Workflows into docker container
Goal is to put the mycosnp-bwa-reference into a docker container, in order to use in a Mycosnp Nextflow workflow.

## Methods
#### The Mycosnp workflows are configured to use singularity, which is not ideal if the workflow will be run in a docker container.
#### For this reason each workflow needs to be modified to contain the 'environment' execution method that allows each app to run locally.
#### The process of modifiying each app consists of adding code and updating the execution methods in two files:
- [1] The bash script of the app
- [2] The workflow yaml file (app.yaml)


#### In order to run each app, the bioinformatics tools need to be downloaded in the local environment. In the case of the Mycosnp-bwa-reference workflow each app uses specific tools 
#### Once all the tools are downloaded and the workflows have been updated, the Mycosnp-bwa-reference workflow can be run. 

### Dockerfile build
#### The Dockerfile is b

