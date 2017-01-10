###############################################################################
#  MINIMAP                                                                    #
###############################################################################

__MINIASM_OUTDIR__ = "%s/miniasm" % WORKDIR

rule minimap:
  input:
    fq = lambda wildcards: "%s/ont_single.%s.fq" % (MERGE_SAMPLE_ONTS_OUTDIR, wildcards.sample_id)
  output:
    aln = "%s/{assembler}/minimap.{sample_id}.gz" % __MINIASM_OUTDIR__
  threads: 4
  params:
    minimap_params = lambda wildcards: tconfig[wildcards.assembler]["minimap_params"],
    rule_outdir = lambda wildcards: "%s/%s" % (__MINIASM_OUTDIR__, wildcards.assembler)
  benchmark: "%s/minimap.{assembler}.{sample_id}" % __LOGS_OUTDIR__
  shell: """
    mkdir -p {params.rule_outdir}
    minimap {params.minimap_params} -t{threads} {input.fq} {input.fq} | gzip -1 > {output.aln}
  """

###############################################################################
#  MINIASM                                                                    #
###############################################################################

rule miniasm:
  input:
    fq  = lambda wildcards: "%s/ont_single.%s.fq" % (MERGE_SAMPLE_ONTS_OUTDIR, wildcards.sample_id),
    aln = lambda wildcards: "%s/%s/minimap.%s.gz" % (__MINIASM_OUTDIR__, wildcards.assembler, wildcards.sample_id)
  output:
    gfa = "%s/{assembler}/miniasm.{sample_id}.gfa" % __MINIASM_OUTDIR__,
    asm = "%s/{assembler}/miniasm.{sample_id}.fa" % __MINIASM_OUTDIR__
  params:
    miniasm_params = lambda wildcards: tconfig[wildcards.assembler]["miniasm_params"]
  benchmark: "%s/asm.{assembler}.{sample_id}" % __LOGS_OUTDIR__
  shell: """
    miniasm {params.miniasm_params} -f {input.fq} {input.aln} > {output.gfa}
    cat {output.gfa} | grep -e "^S" | cut -f3 | awk 'BEGIN{{N=1}}{{print ">contig" N "\\n" $0; N=N+1}}' > {output.asm}
  """

###############################################################################
#  WRAPPER                                                                    #
###############################################################################

rule miniasm_wrapper:
  input:
    asm = lambda wildcards: "%s/%s/%s.%s.fa" % (__MINIASM_OUTDIR__, wildcards.assembler, tconfig[wildcards.assembler]["template"], wildcards.sample_id)
  output:
    asm = "%s/asm.{assembler}.{sample_id}.fa" % ASM_OUTDIR
  threads: 1
  shell: """
    cp {input.asm} {output.asm}
  """

