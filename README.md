Parabricks-NextFlow
-------------------
2023-10-29 tested

# Overview
This repo contains code for running Nvidia Clara Parabricks in NextFlow on local.

# Getting Started
After cloning this repository, you'll need a valid parabricks installation as well as a Parabricks cloud-compatible docker container to run. In addition, you should have at least one Parabricks compatible GPU (VRAM > 16GB) to expect to be able to test.

## Set up an environment
Parabricks-NextFlow requires the following dependencies:

- Docker

https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
docker run --rm hello-world
```

- nvidia-drivers

https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=deb_network

```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-drivers
```

- nvidia-docker

https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installing-with-apt

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
  && \
    sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo docker run --rm --runtime=nvidia --gpus all nvidia/cuda:11.8.0-runtime-ubuntu22.04 nvidia-smi
```

- NextFlow

https://www.nextflow.io/docs/latest/getstarted.html#installation

```bash
sudo apt install -y openjdk-17-jdk
wget -qO- https://get.nextflow.io | bash
chmod +x nextflow
sudo mv nextflow /usr/local/bin
```

After installing these tools, you will need a compatible Parabricks container.

https://catalog.ngc.nvidia.com/orgs/nvidia/teams/clara/containers/clara-parabricks

```bash
sudo docker pull nvcr.io/nvidia/clara/clara-parabricks:4.1.2-1
```

## Prepare the reference genome
```bash
wget http://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz
wget http://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai
wget http://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bwa_index.tar.gz

gunzip GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz
tar axvf GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bwa_index.tar.gz
rm GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bwa_index.tar.gz

tar acvf GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.tar GCA_000001405.15_GRCh38_no_alt_analysis_set.fna*
mkdir ref
mv GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.tar ref/
rm GCA_000001405.15_GRCh38_no_alt_analysis_set.fna*

cd ref/
wget http://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
wget http://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz.tbi
```

## Download test data for ERR194147 (NA12878)
```bash
mkdir test-data
cd test-data

wget http://ftp.sra.ebi.ac.uk/vol1/fastq/ERR194/ERR194147/ERR194147_1.fastq.gz
wget http://ftp.sra.ebi.ac.uk/vol1/fastq/ERR194/ERR194147/ERR194147_2.fastq.gz
```

## Running fq2bam locally
The Parabricks fq2bam tool is an accelerated BWA mem implementation. The tool also includes BAM sorting, duplicate marking, and optionally Base Quality Score Recalibration (BQSR). The `fq2bam.nf` script in this repository demonstrates how to run this tool with a set of input reads, producing a BAM file, its BAI index and a BQSR report for use with HaplotypeCaller.

Below is an example command line for running the fq2bam.nf script:

```bash
nextflow run \
    -c config/local.nf.conf \
    -params-file example_inputs/test.fq2bam.json \
    -with-docker 'nvcr.io/nvidia/clara/clara-parabricks:4.1.2-1' \
    nextflow/fq2bam.nf
```

Note the following:
- The config/local.nf.conf configuration file defines the GPU-enabled local label and should be passed for local runs.
- The `-with-docker` command is required and should point to a valid Parabricks cloud-compatible Docker container. It must have no Entrypoint (i.e., `ENTRYPOINT bash`) and one should note the path to Parabricks within the container.
- The `-params-file` argument allows using a JSON stub for program arguments (rather than the command line). We recommend this way of invoking nextflow as it is easier to debug and more amenable to batch processing.

### Running the germline example
```bash
nextflow run \
    -c config/local.nf.conf \
    -params-file example_inputs/test.germline.json \
    -with-docker 'nvcr.io/nvidia/clara/clara-parabricks:4.1.2-1' \
    nextflow/germline_calling.nf
```
