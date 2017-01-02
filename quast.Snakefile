rule quast:
  input: 
    asm = lambda wildcards: "%s/pilon.%s.%s.fa" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id) 
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

rule quast_sample:
  input:
    asms = lambda wildcards: expand("%s/pilon.{assembler}.%s.fa" % (PILON_OUTDIR, wildcards.sample_id), assembler=__ASSEMBLERS__)
  output:
    rep = "%s/quast_sample.{sample_id}.tsv" % QUAST_OUTDIR
  threads: 4
  params:

  shell: """
    
  """
