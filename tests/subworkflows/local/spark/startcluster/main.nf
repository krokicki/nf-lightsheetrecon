#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { SPARK_START } from '../../../../../subworkflows/local/spark/start/main.nf'
include { SPARK_TERMINATE } from '../../../../../modules/local/spark/terminate/main.nf'

workflow test_spark_startcluster {

    def spark_work_dir = "${workDir}/spark/${workflow.sessionId}"

    // channel: [ spark_uri, spark_work_dir ]
    SPARK_START ( Channel.of(spark_work_dir), 2, 1, 1 )
    | SPARK_TERMINATE
}
