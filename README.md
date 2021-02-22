# MycoSNP GeneFlow Workflows: BWA Reference

## Overview

MycoSNP includes the following set of three GeneFlow workflows:

1. MycoSNP BWA Reference: Prepares a reference FASTA file for BWA alignment and GATK variant calling by masking repeats in the reference and generating the BWA index.
2. MycoSNP BWA Pre-Process: Prepares samples (paired-end FASTQ files) for GATK variant calling by aligning the samples to a BWA reference index and ensuring that the BAM files are correctly formatted.
3. MycoSNP GATK Variants: Calls variants and generates a multi-FASTA file. 

This repository contains the MycoSNP BWA Reference workflow, which consists of three steps:

1. Mask repeats in a reference FASTA file using MUMmer 3.23 and BEDTools 2.29.2.
2. Creates a FASTA index (.fai) and dictionary (.dict) using SAMTools 1.10 and Picard 2.22.9, repectively.
3. Creates a BWA index using BWA 0.7.17.

## Requirements

To run the workflow, please ensure that your computing environment meets the following requirements:

1. Linux Operating System

2. Git

3. SquashFS, required for executing Singularity containers - Most standard Linux distributions have SquashFS installed and enabled by default. However, in the event that SquashFS is not enabled, we recommend that you check with your system administrator to install it. Alternatively, you can enable it by following these instructions (warning: these docs are for advanced users): https://www.tldp.org/HOWTO/html_single/SquashFS-HOWTO/

4. Python 3+

5. Singularity

6. GeneFlow (install instructions below)

7. DRMAA library, required for executing the workflow in an HPC environment

## Installation

First install GeneFlow and its dependencies as follows:

1. Create a Python virtual environment to install dependencies and activate that environment.

    ```bash
    mkdir -p ~/mycosnp
    cd ~/mycosnp
    python3 -m venv ~/mycosnp/gfpy
    source ~/mycosnp/gfpy/bin/activate
    ```
2. Install GeneFlow.

    ```bash
    pip3 install geneflow
    ```

3. Install the Python DRMAA library if you need to execute the workflow in an HPC environment. Skip this step if you do not need HPC.

    ```bash
    pip3 install drmaa
    ```

4. Clone and install the GeneFlow workflow.

    ```bash
    cd ~/mycosnp
    gf install-workflow --make-apps -g https://github.com/CDCgov/mycosnp-bwa-reference mycosnp-bwa-reference
    ```

    The workflow should now be installed in the `~/mycosnp/mycosnp-bwa-reference` directory.

## Execution

View the workflow parameter requirements using GeneFlow's `help` command:

```
cd ~/mycosnp
gf help mycosnp-bwa-reference
```

Execute the workflow with a command similar to:

```
gf --log-level debug run mycosnp-bwa-reference \
    -o ./output \
    -n test-mycosnp-bwa-reference \
    --in.reference_sequence /scicomp/reference/mdb-references/candida-auris_clade-i_B8441_GCA_002759435.2.fasta \
    --ec default:gridengine \
    --ep \
        default.slots:4 \
        'default.init:echo `hostname` && mkdir -p $HOME/tmp && export TMPDIR=$HOME/tmp && export _JAVA_OPTIONS=-Djava.io.tmpdir=$HOME/tmp && export XDG_RUNTIME_DIR='
```

Arguments are explained below:

1. `-o ./output`: The workflow's output will be placed in the `./output` folder. This folder will be created if it doesn't already exist. 
2. `-n test-mycosnp-bwa-reference`: This is the name of the workflow job. A sub-folder with the name `test-mycosnp-bwa-reference` will be created in `./output` for the workflow output. 
3. `--in.reference_sequence`: This is the reference FASTA file to be processed and indexed by the workflow.
4. `--ec default:gridengine`: This is the workflow "execution context", which specifies where the workflow will be executed. "gridengine" is recommended, as this will execute the workflow on the HPC. However, "local" may also be used. 
5. `--ep`: This specifies one or more workflow "execution parameters".
   a. `default.slots:4`: This specifies the number of CPUs or "slots" to request from the gridengine HPC when executing the workflow.
   b. `'default.init:echo `hostname` && mkdir -p $HOME/tmp && export TMPDIR=$HOME/tmp && export _JAVA_OPTIONS=-Djava.io.tmpdir=$HOME/tmp && export XDG_RUNTIME_DIR='`: This specifies a number of commands to execute on each HPC node to prepare that node for execution. These commands ensure that a local "tmp" directory is used (rather than /tmp), and also resets an environment variable that may interfere with correct execution of singularity containers.
   c. `'default.other:-l avx -v PATH'`: This specifies that only "avx" capable nodes should be used to execute the workflow apps, and also that the user's PATH environment variable is passed to the HPC job environment. 

After successful execution, the output directory should contain the following structure:

```
├── bwa_index
│   ├── bwa_index
│   │   ├── bwa_index.amb
│   │   ├── bwa_index.ann
│   │   ├── bwa_index.bwt
│   │   ├── bwa_index.pac
│   │   └── bwa_index.sa
│   └── _log
│       ├── bwa_index-bwa-index.stderr
│       ├── bwa_index-bwa-index.stdout
│       ├── gf-0-bwa_index-bwa_index.err
│       └── gf-0-bwa_index-bwa_index.out
└── index_reference
    ├── indexed_reference
    │   ├── indexed_reference.dict
    │   ├── indexed_reference.fasta
    │   └── indexed_reference.fasta.fai
    └── _log
        ├── gf-0-index_reference-indexed_reference.err
        ├── gf-0-index_reference-indexed_reference.out
        ├── indexed_reference-picard-createsequencedictionary.stderr
        ├── indexed_reference-picard-createsequencedictionary.stdout
        ├── indexed_reference-samtools-faidx.stderr
        └── indexed_reference-samtools-faidx.stdout
```

## Public Domain Standard Notice
This repository constitutes a work of the United States Government and is not
subject to domestic copyright protection under 17 USC § 105. This repository is in
the public domain within the United States, and copyright and related rights in
the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
All contributions to this repository will be released under the CC0 dedication. By
submitting a pull request you are agreeing to comply with this waiver of
copyright interest.

## License Standard Notice
The repository utilizes code licensed under the terms of the Apache Software
License and therefore is licensed under ASL v2 or later.

This source code in this repository is free: you can redistribute it and/or modify it under
the terms of the Apache Software License version 2, or (at your option) any
later version.

This source code in this repository is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the Apache Software License for more details.

You should have received a copy of the Apache Software License along with this
program. If not, see http://www.apache.org/licenses/LICENSE-2.0.html

The source code forked from other open source projects will inherit its license.

## Privacy Standard Notice
This repository contains only non-sensitive, publicly available data and
information. All material and community participation is covered by the
[Disclaimer](https://github.com/CDCgov/template/blob/master/DISCLAIMER.md)
and [Code of Conduct](https://github.com/CDCgov/template/blob/master/code-of-conduct.md).
For more information about CDC's privacy policy, please visit [http://www.cdc.gov/other/privacy.html](https://www.cdc.gov/other/privacy.html).

## Contributing Standard Notice
Anyone is encouraged to contribute to the repository by [forking](https://help.github.com/articles/fork-a-repo)
and submitting a pull request. (If you are new to GitHub, you might start with a
[basic tutorial](https://help.github.com/articles/set-up-git).) By contributing
to this project, you grant a world-wide, royalty-free, perpetual, irrevocable,
non-exclusive, transferable license to all users under the terms of the
[Apache Software License v2](http://www.apache.org/licenses/LICENSE-2.0.html) or
later.

All comments, messages, pull requests, and other submissions received through
CDC including this GitHub page may be subject to applicable federal law, including but not limited to the Federal Records Act, and may be archived. Learn more at [http://www.cdc.gov/other/privacy.html](http://www.cdc.gov/other/privacy.html).

## Records Management Standard Notice
This repository is not a source of government records, but is a copy to increase
collaboration and collaborative potential. All government records will be
published through the [CDC web site](http://www.cdc.gov).

## Additional Standard Notices
Please refer to [CDC's Template Repository](https://github.com/CDCgov/template)
for more information about [contributing to this repository](https://github.com/CDCgov/template/blob/master/CONTRIBUTING.md),
[public domain notices and disclaimers](https://github.com/CDCgov/template/blob/master/DISCLAIMER.md),
and [code of conduct](https://github.com/CDCgov/template/blob/master/code-of-conduct.md).
