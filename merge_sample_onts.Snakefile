###############################################################################
#  MERGE ONT IN SAME SAMPLE                                                   #
###############################################################################

rule merge_sample_onts:
  input:
    onts = lambda wildcards: expand("%s/ont_single.{exp}.fq" % (MERGE_MEASUREMENTS_OUTDIR), exp=sampleExpID_ONTS(wildcards.sample_id))
  output:
    ont = "%s/ont_single.{sample_id}.fq" % MERGE_SAMPLE_ONTS_OUTDIR
  params:
    rule_outdir = MERGE_SAMPLE_ONTS_OUTDIR
  benchmark: "%s/merge_sample_onts.{sample_id}" % __LOGS_OUTDIR__
  shell: """
    mkdir -p {params.rule_outdir}
    cat {input.onts} > {output.ont}
  """

