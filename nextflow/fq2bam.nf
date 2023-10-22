#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/**
 * Clara Parabricks NextFlow
 * fq2bam.nf
*/


/**
* Inputs
*/
params.inputFASTQ_1 = null
params.inputFASTQ_2 = null
params.inputRefTarball = null
params.inputKnownSitesVCF = null
params.inputKnownSitesTBI = null

params.inputSampleName = null
params.platformName = null

params.pbPATH = null

process fq2bam {
    publishDir "$params.outdir", mode: 'copy', overwrite: false
    label 'localGPU'

    input:
    path inputFASTQ_1
    path inputFASTQ_2
    path inputRefTarball
    path inputKnownSitesVCF
    path inputKnownSitesTBI
    val inputSampleName
    val platformName
    val pbPATH

    output:
    path "${inputSampleName}.bam"
    path "${inputSampleName}.bam.bai"
    path "${inputSampleName}.BQSR-REPORT.txt"

    script:
    def knownSitesStub = inputKnownSitesVCF ? "--knownSites ${inputKnownSitesVCF}" : ''
    def recalStub = inputKnownSitesVCF ? "--out-recal-file ${inputSampleName}.BQSR-REPORT.txt" : ''
    def sampleNameStub = inputSampleName ? "--read-group-sm ${inputSampleName}" : ""
    def platformNameStub = platformName ? "--read-group-pl ${platformName}" : ""

    """
    tar xf ${inputRefTarball.Name} && \
    time ${pbPATH} fq2bam \
    --in-fq ${inputFASTQ_1} ${inputFASTQ_2} \
    --ref ${inputRefTarball.baseName} \
    --out-bam ${inputSampleName}.bam \
    ${knownSitesStub} \
    ${recalStub} \
    ${sampleNameStub} \
    ${platformNameStub}
    """
}

workflow ClaraParabricks_fq2bam {
    fq2bam(
        inputFASTQ_1=params.inputFASTQ_1,
        inputFASTQ_2=params.inputFASTQ_2,
        inputRefTarball=params.inputRefTarball,
        inputKnownSitesVCF=params.inputKnownSitesVCF,
        inputKnownSitesTBI=params.inputKnownSitesTBI,
        inputSampleName=params.inputSampleName,
        platformName=params.platformName,
        pbPATH=params.pbPATH
    )
}

workflow {
    ClaraParabricks_fq2bam()
}
