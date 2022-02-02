# Approach to Containerizing MycoSNP Workflows into docker container
Goal is to containerize the mycosnp-bwa-reference into a docker container, in order to use in a Mycosnp Nextflow workflow. The mycosnp pipeline consists of 3 workflows and each workflows consists of a number of apps. In the case of this example, the mycosnp-bwa-reference has three apps:
- [1] mask-repeats
- [2] index-reference
- [3] bwa-index

## Methods
The Mycosnp workflows are configured to use singularity, which is not ideal if the workflow will be run in a docker container.
For this reason each workflow needs to be modified to contain the 'environment' execution method that allows each app to run locally.
The process of modifiying each app consists of adding code and updating the execution methods in two files:
- [1] The bash script of the app
- [2] The workflow yaml file (app.yaml)

In order to run each app, the bioinformatics tools need to be downloaded in the local environment. In the case of the Mycosnp-bwa-reference workflow each app uses specific tools.
Once all the tools are downloaded and the workflows have been updated, the Mycosnp-bwa-reference workflow can be run locally.

The next step is to build a dockerfile that will build this environment in a docker container.

## Dockerfile build
The dockerfile consists of multiple stages and uses geneflows image as a base.
