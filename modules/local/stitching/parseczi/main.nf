process STITCHING_PARSECZI {
    container 'multifish/biocontainers-stitching-spark:1.9.0'
    cpus { driver_cores == 0 ? 1 : driver_cores }
    memory { driver_memory }

    input:
    tuple val(meta), val(files)
    path(input_dir)
    path(output_dir)
    val(workers)
    val(worker_cores)
    val(mem_per_core_in_gb)
    val(driver_cores)
    val(driver_memory)

    output:
    tuple val(meta), val(files), emit: acquisitions
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    extra_args = task.ext.args ?: ''
    executor_memory_in_gb = worker_cores * mem_per_core_in_gb
    executor_memory = executor_memory_in_gb+"g"
    parallelism = workers * worker_cores
    driver_cores_sh = driver_cores ?: 1
    driver_memory_sh = driver_memory.replace(" KB",'k').replace(" MB",'m').replace(" GB",'g').replace(" TB",'t')
    container_engine = workflow.containerEngine
    // Find the MVL metadata file
    mvl = files.findAll { it.extension=="mvl" }.first()
    // Get the CZI filename pattern
    pattern = meta.pattern
    // If there is no pattern, it must be a single CZI file
    if (pattern==null || pattern=='') {
        czis = files.findAll { it.extension=="czi" }
        pattern = czis.first()
    }
    """
    /opt/scripts/runapp.sh "$container_engine" "$meta.spark_work_dir" "$meta.spark_uri" \
        /app/app.jar org.janelia.stitching.ParseCZITilesMetadata \
        $parallelism $worker_cores "$executor_memory" $driver_cores_sh "$driver_memory_sh" \
        -i ${mvl} -b ${input_dir} -f ${pattern} -o ${meta.stitching_dir} ${extra_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spark: \$(cat /opt/spark/VERSION)
        stitching-spark: \$(cat /app/VERSION)
    END_VERSIONS
    """
}
