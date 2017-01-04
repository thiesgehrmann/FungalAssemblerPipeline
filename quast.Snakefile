rule quast_skip:
  input:
    asm = lambda wildcards: __NO_CASE__ if tconfig[wildcards.assembler]["busco_do"] else "%s/pilon.%s.%s.fa" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id)
  output:
    rep = "%s/quast.{assembler}.{sample_id}.tsv" % QUAST_OUTDIR
  shell: """
    touch {output.rep}
  """

###############################################################################

rule quast:
  input: 
    asm = lambda wildcards: "%s/pilon.%s.%s.fa" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id) if tconfig[wildcards.assembler]["quast_do"] else __NO_CASE__
  output:
    rep = "%s/quast.{assembler}.{sample_id}.tsv" % QUAST_OUTDIR
  params:
    ref = lambda wildcards: "" if tconfig[wildcards.assembler]["quast_ref"] is None else "-R %s" % tconfig[wildcards.assembler]["quast_ref"],
    gff = lambda wildcards: "" if tconfig[wildcards.assembler]["quast_gff"] is None else "-G %s" % tconfig[wildcards.assembler]["quast_gff"],
    ers = lambda wildcards: "--est-ref-size %d" % tconfig[wildcards.assembler]["quast_est_ref_size"] if ((tconfig[wildcards.assembler]["quast_est_ref_size"] is not None) and (tconfig[wildcards.assembler]["quast_ref"] is None)) else "",
    euk = lambda wildcards: "--eukaryote" if tconfig[wildcards.assembler]["quast_eukaryote"] else "",
    sca = lambda wildcards: "--scaffolds" if tconfig[wildcards.assembler]["quast_scaffolds"] else "",
    out_dir = lambda wildcards: "%s/quast.%s.%s/" % (QUAST_OUTDIR, wildcards.assembler, wildcards.sample_id),
    label   = lambda wildcards: "-l %s.%s" % (wildcards.assembler, wildcards.sample_id)
  threads: 4
  shell: """
    mkdir -p {params.out_dir}
    quast -o {params.out_dir} -t {threads} {params.ref} {params.gff} {params.ers} {params.euk} {params.sca} {params.label} {input.asm}
    cp {params.out_dir}/report.tsv {output.rep}
  """
    
###############################################################################
# QUAST PER SAMPLE                                                            #
###############################################################################

rule quast_sample_reports:
  input:
   reports = expand("%s/quast_sample.{sample_id}.html" % QUAST_OUTDIR, sample_id=config["sample_list"])

###############################################################################

rule quast_sample:
  input:
    asms = lambda wildcards: expand("%s/pilon.{assembler}.%s.fa" % (PILON_OUTDIR, wildcards.sample_id), assembler=__ASSEMBLERS__)
  output:
    rep = "%s/quast_sample.{sample_id}.html" % QUAST_OUTDIR
  threads: 4
  params:
    ref = "" if tconfig[__ASSEMBLERS__[0]]["quast_ref"] is None else "-R %s" % tconfig[__ASSEMBLERS__[0]]["quast_ref"],
    gff = "" if tconfig[__ASSEMBLERS__[0]]["quast_gff"] is None else "-G %s" % tconfig[__ASSEMBLERS__[0]]["quast_gff"],
    ers = "--est-ref-size %d" % tconfig[__ASSEMBLERS__[0]]["quast_est_ref_size"] if ((tconfig[__ASSEMBLERS__[0]]["quast_est_ref_size"] is not None) and (tconfig[__ASSEMBLERS__[0]]["quast_ref"] is None)) else "",
    euk = "--eukaryote" if tconfig[__ASSEMBLERS__[0]]["quast_eukaryote"] else "",
    sca = "--scaffolds" if tconfig[__ASSEMBLERS__[0]]["quast_scaffolds"] else "",
    out_dir = lambda wildcards: "%s/quast_sample.%s.%s/" % (QUAST_OUTDIR, __ASSEMBLERS__[0], wildcards.sample_id),
    label   = "-l " + ','.join(__ASSEMBLERS__)
  shell: """
    mkdir -p {params.out_dir}
    quast -o {params.out_dir} -t {threads} {params.ref} {params.gff} {params.ers} {params.euk} {params.sca} {params.label} {input.asms}
    cp {params.out_dir}/report.html {output.rep}
  """
