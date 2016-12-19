###############################################################################
#  BUSCO                                                                      #
###############################################################################

rule busco_dataset:
  output:
    tgz  = "%s/dataset.tar.gz" % BUSCO_OUTDIR,
    dir  = "%s/dataset" % BUSCO_OUTDIR
  params:
    rule_outdir = BUSCO_OUTDIR,
    db = tconfig["busco"]["database"]
  shell: """
    wget {params.db} -O {output.tgz}
    tar -xf {output.tgz} -C {params.rule_outdir}
    mv "{params.rule_outdir}/`tar -ztf {output.tgz} | head -n1`" {output.dir}
  """

###############################################################################

rule busco:
  input:
    proteins = lambda wildcards: "%s/augustus.%s.%s.fa" % (AUGUSTUS_OUTDIR, wildcards.assembler, wildcards.sample_id),
    db  = "%s/dataset" % BUSCO_OUTDIR
  output:
    summary = "%s/busco.{assembler}.{sample_id}.summary" % BUSCO_OUTDIR
  threads: 4
  params:
    rule_outdir = BUSCO_OUTDIR
  shell: """
   cd {params.rule_outdir} && BUSCO -i {input.proteins} -f -m prot -l {input.db} -c {threads} -t busco_tmp.{wildcards.assembler}.{wildcards.sample_id} -o busco.{wildcards.assembler}.{wildcards.sample_id}
   cp {params.rule_outdir}/run_busco.{wildcards.assembler}.{wildcards.sample_id}/short_summary_busco.{wildcards.assembler}.{wildcards.sample_id}.txt {output.summary}
  """
    
