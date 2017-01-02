###############################################################################
#  RACON                                                                      #
#  The strategy for the iterations is not something I have seen in other      #
#   Snakemake files.                                                          #
#  The rule "xx_begin" produces the initial input to the loop                 #
#  The rule "xx_end" ensures that the output of each iteration is produced    #
#  The rule "xx_iter" takes as input the output of the previous iteration     #
#   and produces the output for the next iteration                            #
#  We limit the wildcard "{iter}" to match regex [0-9].                       #
#  This prevents a stack overflow as snakemake tries to reconstruct the DAG   #
#  By doing this, snakemake will only evaluate iterations 0,1,2,3,4,5,6,7,8,9 #
#  If we want to have more iterations, we could extend the refex, for example #
#    for 0-19, we could do [1]?[0-9], or                                      #
#    for 2-25, we could do [1]?[0-9]|[2][0-5]                                 #
###############################################################################

rule skip_racon:
  input:
    asm = lambda wildcards: __NOCASE__ if tconfig[wildcards.assembler]["racon_do"] else "%s/asm.%s.%s.fa" % (ASM_OUTDIR, wildcards.assembler, wildcards.sample_id)
  output:
    asm = "%s/racon.{assembler}.{sample_id}.fa" % (RACON_OUTDIR)
  shell: """
    cp {input.asm} {output.asm}
  """

###############################################################################

rule racon_begin:
  input:
    asm = lambda wildcards: "%s/asm.%s.%s.fa" % (ASM_OUTDIR, wildcards.assembler, wildcards.sample_id) if tconfig[wildcards.assembler]["racon_do"] else __NOCASE__
  output:
    asm = "%s/racon.{assembler}.{sample_id}/asm.0.fa" % RACON_OUTDIR
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
    asm   = lambda wildcards: expand("%s/racon.%s.%s/asm.{iter}.fa" % (RACON_OUTDIR, wildcards.assembler, wildcards.sample_id), iter=range(1, tconfig[wildcards.assembler]["racon_maxiter"] + 1))
  output:
    asm = "%s/racon.{assembler}.{sample_id}.fa" % (RACON_OUTDIR)
  params:
    final_asm = lambda wildcards: "%s/racon.%s.%s/asm.%d.fa" % (RACON_OUTDIR, wildcards.assembler, wildcards.sample_id, tconfig[wildcards.assembler]["racon_maxiter"])
  benchmark: "%s/racon_end.{assembler}.{sample_id}" % __LOGS_OUTDIR__
  shell: """
    cp {params.final_asm} {output.asm}
  """

###############################################################################
  # For some reason, the -s option doesn't work in iterative racon runs
rule racon_iter_align:
  input:
    asm = lambda wildcards: "%s/racon.%s.%s/asm.%d.fa" % (RACON_OUTDIR, wildcards.assembler, wildcards.sample_id, int(wildcards.iter)),
    fq  = lambda wildcards: "%s/ont_single.%s.fq" % (MERGE_SAMPLE_ONTS_OUTDIR, wildcards.sample_id)
  output:
    paf = "%s/racon.{assembler}.{sample_id}/paf.{iter,[0-9]}.paf" % RACON_OUTDIR
  threads: 4
  benchmark: "%s/racon_iter_align.{assembler}.{sample_id}" % __LOGS_OUTDIR__
  shell: """
    minimap -w5 -L100 -m0 -t{threads} {input.asm} {input.fq} > {output.paf}
  """

###############################################################################

rule racon_iter_polish:
  input:
    asm = lambda wildcards: "%s/racon.%s.%s/asm.%d.fa"  % (RACON_OUTDIR, wildcards.assembler, wildcards.sample_id, int(wildcards.iter) - 1),
    paf = lambda wildcards: "%s/racon.%s.%s/paf.%d.paf" % (RACON_OUTDIR, wildcards.assembler, wildcards.sample_id, int(wildcards.iter) - 1),
    fq  = lambda wildcards: "%s/ont_single.%s.fq" % (MERGE_SAMPLE_ONTS_OUTDIR, wildcards.sample_id)
  output:
    asm = "%s/racon.{assembler}.{sample_id}/asm.{iter,[0-9]}.fa" % RACON_OUTDIR
  threads: 4
  params:
    tmp_outdir = lambda wildcards: "%s/racon.%s.%s" % (RACON_OUTDIR, wildcards.assembler, wildcards.sample_id),
    iter       = lambda wildcards: wildcards.iter,
    prev_iter  = lambda wildcards: str(int(wildcards.iter)-1),
    max_iter   = lambda wildcards: tconfig[wildcards.assembler]["racon_maxiter"],
    shell_functions = __SHELL_FUNCTIONS__
  benchmark: "%s/racon_iter_polish.{assembler}.{sample_id}" % __LOGS_OUTDIR__
  shell: """
   source {params.shell_functions}
   racon  -t {threads} {input.fq} {input.paf} {input.asm} {output.asm}
   wc -l {output.asm}

   if [ {params.iter} -lt {params.max_iter} ] && [ `cmpFastaSeqs {output.asm} {params.tmp_outdir}/asm.{params.prev_iter}.fa` == "0" ]; then
     for i in `seq $(({params.iter}+1)) {params.max_iter}`; do
       ln -s {output.asm} {params.tmp_outdir}/asm.$i.fa 
     done
   fi 
  """
#fi
