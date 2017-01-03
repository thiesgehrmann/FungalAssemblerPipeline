###############################################################################
#  SPADES                                                                     #
###############################################################################

__SPADES_OUTDIR__ = "%s/spades" % WORKDIR

rule spades:
  input:
    ont_fq  = lambda wildcards: "%s/ont_single.%s.fq" % (MERGE_SAMPLE_ONTS_OUTDIR, wildcards.sample_id) if len(sampleExpID_ILLS(wildcards.sample_id)+sampleExpID_ILLP(wildcards.sample_id)) > 0 else __NO_CASE__,
    r       = lambda wildcards: expand("%s/illumina_single.{exp}.fq" % (MERGE_MEASUREMENTS_OUTDIR), exp=sampleExpID_ILLS(wildcards.sample_id)),
    r1      = lambda wildcards: expand("%s/illumina_paired.{exp}_1.fq" % (MERGE_MEASUREMENTS_OUTDIR), exp=sampleExpID_ILLP(wildcards.sample_id)),
    r2      = lambda wildcards: expand("%s/illumina_paired.{exp}_2.fq" % (MERGE_MEASUREMENTS_OUTDIR), exp=sampleExpID_ILLP(wildcards.sample_id))
  output:
    asm = "%s/{assembler}/spades.{sample_id}.fa" % __SPADES_OUTDIR__
  threads: 16
  params:
    spades_params = lambda wildcards: tconfig[wildcards.assembler]["spades_params"],
    out_dir = lambda wildcards: "%s/%s/%s" % (__SPADES_OUTDIR__, wildcards.assembler, wildcards.sample_id),
    srl     = lambda wildcards: ' '.join(['-s %s/illumina_single.{exp}.fq' % (MERGE_MEASUREMENTS_OUTDIR, exp) for exp in sampleExpID_ILLS(wildcards.sample_id)]),
    pel     = lambda wildcards: ' '.join(['--pe%d-1 %s/illumina_paired.%s_1.fq --pe%d-2 %s/illumina_paired.%s_2.fq' % (i+1, MERGE_MEASUREMENTS_OUTDIR, exp, i+1, MERGE_MEASUREMENTS_OUTDIR, exp) for (i, exp) in enumerate(sampleExpID_ILLP(wildcards.sample_id))])
  benchmark: "%s/spades.{assembler}.{sample_id}" % __LOGS_OUTDIR__
  shell: """
    mkdir -p {params.out_dir}
    spades.py -t {threads} {params.spades_params} {params.srl} {params.pel} --nanopore {input.ont_fq} -o {params.out_dir}
    cp {params.out_dir}/scaffolds.fasta {output.asm} 
  """

###############################################################################
#  WRAPPER                                                                    #
###############################################################################

rule spades_wrapper:
  input:
    asm = lambda wildcards: "%s/%s/%s.%s.fa" % (__SPADES_OUTDIR__, wildcards.assembler, tconfig[wildcards.assembler]["template"], wildcards.sample_id)
  output:
    asm = "%s/asm.{assembler}.{sample_id}.fa" % ASM_OUTDIR
  threads: 1
  shell: """
    cp {input.asm} {output.asm}
  """

