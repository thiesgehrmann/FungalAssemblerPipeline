###############################################################################
# COMBINE METRICS                                                             #
###############################################################################

rule asm_sample_metrics:
  input:
    busco = lambda wildcards: "%s/busco.%s.%s.summary" % (BUSCO_OUTDIR, wildcards.assembler, wildcards.sample_id) if tconfig[wildcards.assembler]["busco_do"] else "/dev/null", 
    quast = lambda wildcards: "%s/quast.%s.%s.tsv"     % (QUAST_OUTDIR, wildcards.assembler, wildcards.sample_id) if tconfig[wildcards.assembler]["quast_do"] else "/dev/null"
  output:
    metric = "%s/metrics.{assembler}.{sample_id}.tsv" % METRICS_OUTDIR
  params:
    assembler = lambda wildcards: wildcards.assembler,
    sample_id = lambda wildcards: wildcards.sample_id
  shell: """
    cat {input.quast} \
      | grep -v "#" \
      | cut -f1,2 \
      | tail -n+2 \
      | sed -e 's/^.*$/{params.assembler}\t{params.sample_id}\t&/' \
      > {output.metric}

    cat {input.busco} \
      | grep "%" \
      | tr '[,' '\n\n' \
      | tr -d ' \t]' \
      | grep -v '^n:' \
      | sed -e 's/^C:/Busco complete\t/' \
            -e 's/^S:/Busco single\t/' \
            -e 's/^D:/Busco duplicate\t/' \
            -e 's/^F:/Busco Fragmented\t/' \
            -e 's/^M:/Busco Missing\t/' \
      | sed -e 's/^.*$/{params.assembler}\t{params.sample_id}\t&/' \
      >> {output.metric}    
  """

############################################################################### 

rule metrics_merge:
  input:
    metrics = expand("%s/metrics.{assembler}.{sample_id}.tsv" % METRICS_OUTDIR, assembler=__ASSEMBLERS__, sample_id=config["sample_list"])
  output:
    metrics = "%s/metrics_merged.tsv" % METRICS_OUTDIR
  shell: """
    cat {input.metrics} > {output.metrics}
  """

###############################################################################

rule metrics_pivot:
  input:
    metrics = "%s/metrics_merged.tsv" % METRICS_OUTDIR
  output:
    metrics = "%s/metrics.tsv" % METRICS_OUTDIR
  shell: """
    echo 'import pandas as pd; \
          import sys; \
          met = pd.read_table("{input.metrics}", names=("asm", "sample", "metric", "value")); \
          met["idx"] = met["asm"] + "." + met["sample"]; \
          met = met.pivot(index="idx", columns="metric", values="value"); \
          met.to_csv(sys.stdout, sep="\t")' \
      | python2 \
      | sed -e 's/^idx/assembler\tsample_id/' \
      | sed -e 's/[.]/\t/' \
      > {output.metrics}
    """
