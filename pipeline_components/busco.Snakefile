###############################################################################
#  BUSCO                                                                      #
###############################################################################

rule busco_dataset:
  output:
    tgz  = "%s/dataset.{assembler}.tar.gz" % BUSCO_OUTDIR,
    dir  = "%s/dataset.{assembler}" % BUSCO_OUTDIR
  params:
    db = lambda wildcards: tconfig[wildcards.assembler]["busco_database"]
  shell: """
    wget {params.db} -O {output.tgz}
    mkdir -p {output.dir}
    tar -xf {output.tgz} --strip-components=1 -C {output.dir}
  """

###############################################################################

rule busco_skip:
  input:
    asm = lambda wildcards: __NOCASE__ if tconfig[wildcards.assembler]["busco_do"] else "%s/pilon.%s.%s.fa" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id)
  output:
    summary = "%s/busco.{assembler}.{sample_id}.summary" % BUSCO_OUTDIR
  shell: """
    touch {output.summary}
  """

###############################################################################

rule busco:
  input:
    proteins = lambda wildcards: "%s/augustus.%s.%s.fa" % (AUGUSTUS_OUTDIR, wildcards.assembler, wildcards.sample_id) if tconfig[wildcards.assembler]["busco_do"] else __NOCASE__,
    db       = lambda wildcards: "%s/dataset.%s" % (BUSCO_OUTDIR, wildcards.assembler)
  output:
    summary = "%s/busco.{assembler}.{sample_id}.summary" % BUSCO_OUTDIR
  threads: 4
  params:
    rule_outdir = BUSCO_OUTDIR
  shell: """
   cd {params.rule_outdir} && BUSCO -i {input.proteins} -f -m prot -l {input.db} -c {threads} -t busco_tmp.{wildcards.assembler}.{wildcards.sample_id} -o busco.{wildcards.assembler}.{wildcards.sample_id}
   cp {params.rule_outdir}/run_busco.{wildcards.assembler}.{wildcards.sample_id}/short_summary_busco.{wildcards.assembler}.{wildcards.sample_id}.txt {output.summary}
  """
    
