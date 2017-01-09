###############################################################################
#  CANU                                                                       #
###############################################################################

# Will be a good idea to consider these things:
#  http://canu.readthedocs.io/en/latest/faq.html

__CANU_OUTDIR__ = "%s/canu/" % WORKDIR

rule canu_correct_end:
  input: 
    fq   = lambda wildcards: expand("%s/%s/correction/correct.%s.{iter}.fasta.gz" % (__CANU_OUTDIR__, wildcards.assembler, wildcards.sample_id), iter=range(1, tconfig[wildcards.assembler]["canu_correct_iter"]+1)),
    last = lambda wildcards: "%s/%s/correction/correct.%s.%d.fasta.gz" % (__CANU_OUTDIR__, wildcards.assembler, wildcards.sample_id, tconfig[wildcards.assembler]["canu_correct_iter"])
  output:
    fq = "%s/{assembler}/correction/correct.{sample_id}.final.fasta.gz" % (__CANU_OUTDIR__)
  shell: """
    ln -s {input.last} {output.fq}
  """

###############################################################################
# I have to run canu correct here already because it produces a FASTA file as output.
# The loop therefore requires a fasta file as initialization

rule canu_correct_begin:
  input:
    fq = lambda wildcards: "%s/ont_single.%s.fq" % (MERGE_SAMPLE_ONTS_OUTDIR, wildcards.sample_id)
  output:
    fa = "%s/{assembler}/correction/correct.{sample_id}.1.fasta.gz" % __CANU_OUTDIR__
  params:
    rule_outdir = __CANU_OUTDIR__,
    params      = lambda wildcards: tconfig[wildcards.assembler]["canu_params"],
    genome_size = lambda wildcards: tconfig[wildcards.assembler]["canu_genomesize"],
    corr_params = lambda wildcards: tconfig[wildcards.assembler]["canu_correct_params"],
    maxmem      = lambda wildcards: tconfig[wildcards.assembler]["canu_maxmem"],
    output_dir  = lambda wildcards: "%s/%s/correction/correct.%s.1/" % (__CANU_OUTDIR__, wildcards.assembler, wildcards.sample_id)
  shell: """
    mkdir -p {params.output_dir}
    canu -correct \
      -p {wildcards.sample_id} \
      -d {params.output_dir} \
      genomeSize={params.genome_size} \
      {params.params} \
      {params.corr_params} \
      maxMemory={params.maxmem} \
      maxThreads={threads} \
      -nanopore-raw {input.fq}
    mv {params.output_dir}/{wildcards.sample_id}.correctedReads.fasta.gz {output.fa}
  """

###############################################################################

rule canu_correct_iter:
  input:
    fa = lambda wildcards: "%s/%s/correction/correct.%s.%d.fasta.gz" % (__CANU_OUTDIR__, wildcards.assembler, wildcards.sample_id, int(wildcards.iter)-1)
  output:
    fa = "%s/{assembler}/correction/correct.{sample_id}.{iter,[0-9]}.fasta.gz" % __CANU_OUTDIR__
  threads: 4
  params:
    params      = lambda wildcards: tconfig[wildcards.assembler]["canu_params"],
    genome_size = lambda wildcards: tconfig[wildcards.assembler]["canu_genomesize"],
    corr_params = lambda wildcards: tconfig[wildcards.assembler]["canu_correct_params"],
    maxmem      = lambda wildcards: tconfig[wildcards.assembler]["canu_maxmem"],
    output_dir  = lambda wildcards: "%s/%s/correction/correct.%s.%s/" % (__CANU_OUTDIR__, wildcards.assembler, wildcards.sample_id, wildcards.iter)
  shell: """
    mkdir -p {params.output_dir}
    canu -correct \
      -p {wildcards.sample_id} \
      -d {params.output_dir} \
      genomeSize={params.genome_size} \
      {params.params} \
      {params.corr_params} \
      maxMemory={params.maxmem} \
      maxThreads={threads} \
      -nanopore-raw {input.fa}
    ln -s {params.output_dir}/{wildcards.sample_id}.correctedReads.fasta.gz {output.fa}
  """
    
###############################################################################

rule canu_trim:
  input:
    fa = lambda wildcards: "%s/%s/correction/correct.%s.final.fasta.gz" % (__CANU_OUTDIR__, wildcards.assembler, wildcards.sample_id)
  output:
    fa = "%s/{assembler}/trim/trimmed.{sample_id}.fasta.gz" % __CANU_OUTDIR__
  threads: 4
  params:
    params      = lambda wildcards: tconfig[wildcards.assembler]["canu_params"],
    genome_size = lambda wildcards: tconfig[wildcards.assembler]["canu_genomesize"],
    corr_params = lambda wildcards: tconfig[wildcards.assembler]["canu_trim_params"],
    maxmem      = lambda wildcards: tconfig[wildcards.assembler]["canu_maxmem"],
    output_dir  = lambda wildcards: "%s/%s/trimmed/trim.%s/" % (__CANU_OUTDIR__, wildcards.assembler, wildcards.sample_id)
  shell: """
    mkdir -p {params.output_dir}
    canu -trim \
      -p {wildcards.sample_id} \
      -d {params.output_dir} \
      genomeSize={params.genome_size} \
      {params.params} \
      {params.corr_params} \
      maxMemory={params.maxmem} \
      maxThreads={threads} \
      -nanopore-raw {input.fa}
    ln -s {params.output_dir}/{wildcards.sample_id}.trimmedReads.fasta.gz {output.fa}
  """
    

###############################################################################

rule canu_assemble:
  input:
    fa = lambda wildcards: "%s/%s/trim/trimmed.%s.fasta.gz" % (__CANU_OUTDIR__, wildcards.assembler, wildcards.sample_id)
  output:
    asm = "%s/{assembler}/canu.{sample_id}.fa"  % (__CANU_OUTDIR__),
    gfa = "%s/{assembler}/canu.{sample_id}.gfa" % (__CANU_OUTDIR__)
  params:
    genome_size = lambda wildcards: tconfig[wildcards.assembler]["canu_genomesize"],
    maxmem      = lambda wildcards: tconfig[wildcards.assembler]["canu_maxmem"],
    params      = lambda wildcards: tconfig[wildcards.assembler]["canu_params"],
    asm_params  = lambda wildcards: tconfig[wildcards.assembler]["canu_assemble_params"],
    output_dir  = lambda wildcards: "%s/%s/%s" % (__CANU_OUTDIR__, wildcards.assembler, wildcards.sample_id)
  threads: 4
  benchmark: "%s/asm.{assembler}.{sample_id}" % __LOGS_OUTDIR__
  shell: """
    mkdir -p {params.output_dir}
    canu -assemble \
         -p {wildcards.sample_id} \
         -d {params.output_dir} \
         maxMemory={params.maxmem} \
         maxThreads={threads} \
         genomeSize={params.genome_size} \
         {params.params} \
         {params.asm_params} \
         -nanopore-corrected {input.fa}
    ln -s {params.output_dir}/{wildcards.sample_id}.unitigs.fasta {output.asm}
    ln -s {params.output_dir}/{wildcards.sample_id}.unitigs.gfa {output.gfa}
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
    ln -s {input.asm} {output.asm}
  """

