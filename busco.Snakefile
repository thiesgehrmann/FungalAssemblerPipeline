###############################################################################
#  CANU                                                                       #
###############################################################################

rule busco_dataset:
  output:
    db = "%s/dataset.tar.gz" % BUSCO_OUTDIR
  params:
    db = __BUSCO_DATASET__
  shell: """
    wget {params.db} -O {output.db}
  """


rule busco:
  input:
    proteins = lambda wildcards: "%s/asm.%s.%s.fa" % (ASM_OUTDIR, wildcards.assembler, wildcards.sample_id)
    gff = "%s/augustus.{assembler}.{sample_id}.prots.fasta"
    db  = "%s/dataset.tar.gz" % BUSCO_OUTDIR
  output:
    
  threads: 4
  params:
  shell: """
  """
    
