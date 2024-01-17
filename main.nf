#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.input = "samplesheet.csv"
params.source = "local"
params.pathmode = "relative"

params.outdir = "results/"

process fetch_url {
    input:
    tuple val(id), val(url)

    output:
    tuple val(id), path("outfile")

    script:
    """
    curl ${url} > outfile
    """
}

process fetch_af {
    input:
    tuple val(id), val(dbacc)

    output:
    tuple val(id), path("outfile")

    script:
    """
    curl https://alphafold.ebi.ac.uk/files/AF-${dbacc}-F1-model_v4.pdb > outfile
    """
}

process extract_structure {
    publishDir params.outdir + "tables/", mode: 'symlink'

    input:
    path pyscript
    tuple val(id), path(query)

    output:
    path "${id}.tsv"

    script:
    """
    python3 ${pyscript} ${query} > ${id}.tsv
    """
}

process plot {
    publishDir params.outdir, mode: 'symlink'

    input:
    path rscript
    path structure_list

    output:
    path "plot.png"

    script:
    """
    Rscript ${rscript} ${structure_list} plot.png
    """
}

workflow read_samples {
    take:
    samplesheet

    main:
    Channel
        .fromPath(samplesheet)
        .splitCsv( header:true, sep:',' )
        .set { sample_list }

    emit:
    sample_list
}

workflow SECANALYZE {
    extract_script = params.SCRIPTS + "extract.py"
    plot_script = params.SCRIPTS + "plot.R"
    
    if (params.source == "local")
    {
        if (params.pathmode == "relative") 
        {
            read_samples(params.input)
            .map { [it.sample, params.PARENT + "/" + it.pdb] }
            .set { samples }
        }
        else if (params.pathmode == "absolute")
        {
            read_samples(params.input)
            .map { [it.sample, it.pdb] }
            .set { samples }
        }
        else
        {
            exit(1, "Unrecognized pathmode: ${params.pathmode}")
        }
    } 
    else if (params.source == "url") 
    {
        read_samples(params.input)
        .map { [it.sample, it.pdb] }
        .set { urls }

        fetch_url(urls)
        .set { samples }
    }
    else if (params.source = "afdb")
    {
        read_samples(params.input)
        .map { [it.sample, it.pdb] }
        .set { dbacc }

        fetch_af(dbacc)
        .set { samples }
    }
    else
    {
        exit(1, "Source not recognized: ${source}")
    }
    
    extract_structure(extract_script, samples)
    .map { it -> "$it" }
    .collectFile(name: "structures.txt", newLine: true)
    .set { structure_list }

    plot(plot_script, structure_list)
}

workflow {
    SECANALYZE()
}