###############################################################################
#  CANU                                                                       #
###############################################################################

__CANU_OUTDIR__ = "%s/canu/" % WORKDIR

rule canu:
  input:
    fq = lambda wildcards: "%s/ont_single.%s.fq" % (MERGE_SAMPLE_ONTS_OUTDIR, wildcards.sample_id)
  output:
    asm = "%s/{sample_id}/{sample_id}.unitigs.fasta" % (__CANU_OUTDIR__),
    gfa = "%s/{sample_id}/{sample_id}.unitigs.gfa" % (__CANU_OUTDIR__)
  params:
    genome_size = CANU_GENOMESIZE,
    output_dir  = lambda wildcards: "%s/%s" % (__CANU_OUTDIR__, wildcards.sample_id),
    maxmem      = CANU_MAXMEM
  threads: 4
  shell: """
    mkdir -p {params.output_dir}
    canu -p {sample_id} \
         -d {params.output_dir} \
         maxMemory={params.maxmem} \
         maxThreads={threads} \
         genomeSize={params.genome_size} \
         -nanopore-raw {input.fq}
  """
###############################################################################
#  WRAPPER                                                                    #
###############################################################################

rule canu_wrapper:
  input:
    asm = lambda wildcards: "%s/%s/%s.unitigs.fasta" % (__CANU_OUTDIR__, wildcards.sample_id, wildcards.sample_id)
  output:
    asm = "%s/asm.canu.{sample_id}.fa" % ASM_OUTDIR
  shell: """
    cp {input.asm} {output.asm}
  """
