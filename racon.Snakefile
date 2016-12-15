###############################################################################
#  RACON                                                                      #
###############################################################################

rule racon_begin:
  input:
    asm = lambda wildcards: "%s/asm.%s.%s.fa" % (ASM_OUTDIR, wildcards.assembler, wildcards.sample_id)
  output:
    asm = "%s/racon.{assembler}.{sample_id}/0.fa" % RACON_OUTDIR
  params:
    tmp_outdir = lambda wildcards: "%s/racon.%s.%s" % (RACON_OUTDIR, wildcards.assembler, wildcards.sample_id),
  benchmark: "%s/racon_begin.{assembler}.{sample_id}" % __LOGS_OUTDIR__
  shell: """
    mkdir -p {params.tmp_outdir}
    cp {input.asm} {output.asm}
  """

###############################################################################

rule racon_end:
  input:
    asm   = lambda wildcards: expand("%s/racon.%s.%s/{iter}.fa" % (RACON_OUTDIR, wildcards.assembler, wildcards.sample_id), iter=range(1, __RACON_MAX_ITER__ + 1))
  output:
    asm = "%s/racon.{assembler}.{sample_id}.fa" % (RACON_OUTDIR)
  params:
    final_asm = lambda wildcards: "%s/racon.%s.%s/%d.fa" % (RACON_OUTDIR, wildcards.assembler, wildcards.sample_id, __RACON_MAX_ITER__)
  benchmark: "%s/racon_end.{assembler}.{sample_id}" % __LOGS_OUTDIR__
  shell: """
    cp {params.final_asm} {output.asm}
  """

###############################################################################

rule racon_iter_align:
  input:
    asm = lambda wildcards: "%s/racon.%s.%s/%d.fa" % (RACON_OUTDIR, wildcards.assembler, wildcards.sample_id, int(wildcards.iter)),
    fq  = lambda wildcards: "%s/ont_single.%s.fq" % (MERGE_SAMPLE_ONTS_OUTDIR, wildcards.sample_id)
  output:
    paf = "%s/racon.{assembler}.{sample_id}/{iter,[0-9]}.paf" % RACON_OUTDIR
  threads: 4
  benchmark: "%s/racon_iter_align.{assembler}.{sample_id}" % __LOGS_OUTDIR__
  shell: """
    minimap -Sw5 -L100 -m0 -t{threads} {input.asm} {input.fq} > {output.paf}
  """

###############################################################################

rule racon_iter_polish:
  input:
    asm = lambda wildcards: "%s/racon.%s.%s/%d.fa"  % (RACON_OUTDIR, wildcards.assembler, wildcards.sample_id, int(wildcards.iter) - 1),
    paf = lambda wildcards: "%s/racon.%s.%s/%d.paf" % (RACON_OUTDIR, wildcards.assembler, wildcards.sample_id, int(wildcards.iter) - 1),
    fq  = lambda wildcards: "%s/ont_single.%s.fq" % (MERGE_SAMPLE_ONTS_OUTDIR, wildcards.sample_id)
  output:
    asm = "%s/racon.{assembler}.{sample_id}/{iter,[0-9]}.fa" % RACON_OUTDIR
  threads: 4
  params:
    tmp_outdir = lambda wildcards: "%s/racon.%s.%s" % (RACON_OUTDIR, wildcards.assembler, wildcards.sample_id),
    iter       = lambda wildcards: wildcards.iter,
    prev_iter  = lambda wildcards: str(int(wildcards.iter)-1),
    max_iter   = __RACON_MAX_ITER__,
    cmpFastaSeqs = cmpFastaSeqs
  benchmark: "%s/racon_iter_polish.{assembler}.{sample_id}" % __LOGS_OUTDIR__
  shell: """
   {params.cmpFastaSeqs}
   racon -v 0 -t {threads} {input.fq} {input.paf} {input.asm} {output.asm}

   if [ {params.iter} -lt {params.max_iter} ] && [ `cmpFastaSeqs {params.tmp_outdir}/{params.iter}.fa {params.tmp_outdir}/{params.prev_iter}.fa` == "0" ]; then
     for i in `seq {params.iter}`; do
       cp {output.asm} {params.tmp_outdir}/$i.fa 
     done
   fi 
  """

