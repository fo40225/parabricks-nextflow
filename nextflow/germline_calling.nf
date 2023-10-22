#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/**
 * Clara Parabricks NextFlow
 * germline_calling.nf
*/


/**
* Inputs
*/
params.inputBAM = null
params.inputBAI = null
params.inputBQSR = null
params.inputRefTarball = null

params.gvcfMode = false

params.pbPATH = null

process haplotypecaller {
    publishDir "$params.outdir", mode: 'copy', overwrite: false
    label 'localGPU'

    input:
    path inputBAM
    path inputBAI
    path inputBQSR
    path inputRefTarball
    val gvcfMode
    val pbPATH

    output:
    path "${inputBAM.baseName}.haplotypecaller.vcf"

    script:
    def bqsrStub = inputBQSR ? "--in-recal-file ${inputBQSR}" : ""
    def gvcfStub = gvcfMode ? "--gvcf" : ""

    """
    tar xf ${inputRefTarball.Name} && \
    time ${pbPATH} haplotypecaller \
    --ref ${inputRefTarball.baseName} \
    --in-bam ${inputBAM} \
    --out-variants "${inputBAM.baseName}.haplotypecaller.vcf" \
    ${gvcfStub} \
    ${bqsrStub}
    """
}

process deepvariant {
    publishDir "$params.outdir", mode: 'copy', overwrite: false
    label 'localGPU'

    input:
    path inputBAM
    path inputBAI
    path inputRefTarball
    val gvcfMode
    val pbPATH

    output:
    path "${inputBAM.baseName}.deepvariant.vcf"

    script:
    def gvcfStub = gvcfMode ? "--gvcf" : ""

    """
    tar xf ${inputRefTarball.Name} && \
    time ${pbPATH} deepvariant \
    --in-bam ${inputBAM} \
    --ref ${inputRefTarball.baseName} \
    --out-variants ${inputBAM.baseName}.deepvariant.vcf \
    ${gvcfStub}
    """
}

workflow ClaraParabricks_Germline {
    haplotypecaller(
        inputBAM=params.inputBAM,
        inputBAI=params.inputBAI,
        inputBQSR=params.inputBQSR,
        inputRefTarball=params.inputRefTarball,
        gvcfMode=params.gvcfMode,
        pbPATH=params.pbPATH
    )
    deepvariant(
        inputBAM=params.inputBAM,
        inputBAI=params.inputBAI,
        inputRefTarball=params.inputRefTarball,
        gvcfMode=params.gvcfMode,
        pbPATH=params.pbPATH
    )
}

workflow {
    ClaraParabricks_Germline()
}