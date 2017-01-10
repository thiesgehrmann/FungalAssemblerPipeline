rule fastqc:
  input:
   report = lambda wildcards: expand("%s/{sample_id}/.tsv" % FASTQC_OUTDIR, sample_id=config["sample_list"])

###############################################################################

rule fastqc_sample:
  input:
    
  output:

  input:
    fqs_rs  = lambda wildcards: [ r["r"] for r in config["data"] if r["experiment_id"] in (sampleExpID_ONTS(wildcards.sample_id) + sampleExpID_ILLS(wildcards.sample_id) ],
    fqs_rp = lambda wildcards: flat([ (r["r1"],r["r2"]) for r in config["data"] if r["experiment_id"] in (sampleExpID_ILLP(wildcards.sample_id) ]),
  output:
    report = "%s/fastqc.{sample_id}.tsv" % FASTQC_OUTDIR
  threads: 2
  params:
    rule_outdir = lambda wildcards: "%s/%s" % (FASTQC_OUTDIR, wildcards.sample_id
  shell: """
    mkdir -p {params.rule_outdir}
    fastqc -o {params.rule_outdir} {input.fqs_rs} {input.fqs_rp}
  """
  
