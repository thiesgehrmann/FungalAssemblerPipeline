###############################################################################
#  CANU                                                                       #
###############################################################################

# Will be a good idea to consider these things:
#  http://canu.readthedocs.io/en/latest/faq.html

__CANU_OUTDIR__ = "%s/canu/" % WORKDIR

rule canu:
  input:
    fq = lambda wildcards: "%s/ont_single.%s.fq" % (MERGE_SAMPLE_ONTS_OUTDIR, wildcards.sample_id)
  output:
    asm  = "%s/{assembler}/{sample_id}/{sample_id}.unitigs.fasta" % (__CANU_OUTDIR__),
    gfa  = "%s/{assembler}/{sample_id}/{sample_id}.unitigs.gfa" % (__CANU_OUTDIR__),
    copy = "%s/{assembler}/canu.{sample_id}.fa" % (__CANU_OUTDIR__)
  params:
    genome_size = lambda wildcards: tconfig[wildcards.assembler]["canu_genomesize"],
    maxmem      = lambda wildcards: tconfig[wildcards.assembler]["canu_maxmem"],
    params      = lambda wildcards: tconfig[wildcards.assembler]["canu_params"],
    output_dir  = lambda wildcards: "%s/%s/%s" % (__CANU_OUTDIR__, wildcards.assembler, wildcards.sample_id)
  threads: 4
  benchmark: "%s/asm.{assembler}.{sample_id}" % __LOGS_OUTDIR__
  shell: """
    mkdir -p {params.output_dir}
    canu -p {wildcards.sample_id} \
         -d {params.output_dir} \
         maxMemory={params.maxmem} \
         maxThreads={threads} \
         genomeSize={params.genome_size} \
         {params.params} \
         -nanopore-raw {input.fq}
    cp {output.asm} {output.copy}
  """
###############################################################################
#  WRAPPER                                                                    #
###############################################################################

rule canu_wrapper:
  input:
    asm = lambda wildcards: "%s/%s/%s.%s.fa" % (__CANU_OUTDIR__, wildcards.assembler, tconfig[wildcards.assembler]["template"], wildcards.sample_id)
  output:
    asm = "%s/asm.{assembler}.{sample_id}.fa" % ASM_OUTDIR
  shell: """
    cp {input.asm} {output.asm}
  """
