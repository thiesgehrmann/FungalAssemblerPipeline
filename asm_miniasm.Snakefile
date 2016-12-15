###############################################################################
#  MINIMAP                                                                    #
###############################################################################
MINIMAP_OUTDIR = "%s/minimap" % WORKDIR

rule minimap:
  input:
    fq = lambda wildcards: "%s/ont_single.%s.fq" % (MERGE_SAMPLE_ONTS_OUTDIR, wildcards.sample_id)
  output:
    aln = "%s/minimap.{sample_id}.gz" % MINIMAP_OUTDIR
  threads: 4
  shell: """
    minimap -Sw5 -L100 -m0 -t{threads} {input.fq} {input.fq} | gzip -1 > {output.aln}
  """

###############################################################################
#  MINIASM                                                                    #
###############################################################################
MINIASM_OUTDIR = "%s/miniasm" % WORKDIR

rule miniasm:
  input:
    fq  = lambda wildcards: "%s/ont_single.%s.fq" % (MERGE_SAMPLE_ONTS_OUTDIR, wildcards.sample_id),
    aln = lambda wildcards: "%s/minimap.%s.gz" % (MINIMAP_OUTDIR, wildcards.sample_id)
  output:
    gfa = "%s/miniasm.{sample_id}.gfa" % MINIASM_OUTDIR,
    asm = "%s/miniasm.{sample_id}.fa" % MINIASM_OUTDIR
  params:
    rule_outdir = MINIASM_OUTDIR
  shell: """
    mkdir -p {params.rule_outdir}
    miniasm -f {input.fq} {input.aln} > {output.gfa}
    cat {output.gfa} | grep -e "^S" | cut -f3 | awk 'BEGIN{{N=1}}{{print ">contig" N "\\n" $0; N=N+1}}' > {output.asm}
  """

###############################################################################
#  WRAPPER                                                                    #
###############################################################################

rule miniasm_wrapper:
  input:
    asm = lambda wildcards: "%s/miniasm.%s.fa" % (MINIASM_OUTDIR, wildcards.sample_id)
  output:
    asm = "%s/asm.miniasm.{sample_id}.fa" % ASM_OUTDIR
  threads: 1
  shell: """
    cp {input.asm} {output.asm}
  """

