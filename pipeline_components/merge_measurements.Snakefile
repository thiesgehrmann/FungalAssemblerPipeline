###############################################################################
#  MERGE ALL MEASUREMENTS INTO ONE                                            #
###############################################################################

rule merge_measurements_single_ont:
  input:
    fq_r  = lambda wildcards:[ x["r"] for x in config["data"] if (x["experiment_id"] == wildcards.exp and x["data_type"] == "OXFORD_NANOPORE") ]
  output:
    fq = "%s/ont_single.{exp}.fq" % MERGE_MEASUREMENTS_OUTDIR
  threads: 1
  params:
    rule_outdir = MERGE_MEASUREMENTS_OUTDIR
  shell: """
    mkdir -p "{params.rule_outdir}"
    cat {input.fq_r} > {output.fq}
    """

rule merge_measurements_illumina_single:
  input:
    fq_r = lambda wildcards: [ x["r"] for x in config["data"] if (x["experiment_id"] == wildcards.exp and x["data_type"] == "ILLUMINA" and x["library_layout"] == "SINGLE") ]
  output:
    fq_r = "%s/illumina_single.{exp}.fq" % MERGE_MEASUREMENTS_OUTDIR
  threads: 1
  params:
    rule_outdir = MERGE_MEASUREMENTS_OUTDIR
  shell: """
    mkdir -p "{params.rule_outdir}"
    cat {input.fq_r} > {output.fq_r}
    """

rule merge_measurements_illumina_paired:
  input:
    fq_r1 = lambda wildcards: [ x["r1"] for x in config["data"] if (x["experiment_id"] == wildcards.exp and x["data_type"] == "ILLUMINA" and x["library_layout"] == "PAIRED") ],
    fq_r2 = lambda wildcards: [ x["r2"] for x in config["data"] if (x["experiment_id"] == wildcards.exp and x["data_type"] == "ILLUMINA" and x["library_layout"] == "PAIRED")]
  output:
    fq_r1 = "%s/illumina_paired.{exp}_1.fq" % MERGE_MEASUREMENTS_OUTDIR,
    fq_r2 = "%s/illumina_paired.{exp}_2.fq" % MERGE_MEASUREMENTS_OUTDIR
  threads: 1
  params:
    rule_outdir = MERGE_MEASUREMENTS_OUTDIR
  shell: """
    mkdir -p "{params.rule_outdir}" 
    cat {input.fq_r1} > {output.fq_r1}
    cat {input.fq_r2} > {output.fq_r2}
    """
