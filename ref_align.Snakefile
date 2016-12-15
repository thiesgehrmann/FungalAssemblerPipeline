###############################################################################
#  INTERNAL VARIABLES                                                         #
###############################################################################

__REF_ALIGN_HIDDEN__ = "%s/TRUEFILES" % REF_ALIGN_OUTDIR

###############################################################################
#  BWA INDEX                                                                  #
###############################################################################
BWA_INDEX_OUTDIR = "%s/bwa_index" % WORKDIR

rule bwa_build:
  input:
    asm = lambda wildcards: "%s/asm.%s.%s.fa" % (ASM_OUTDIR, wildcards.assembler, wildcards.sample_id)
  output:
    index = ["%s/bwa_index.{assembler}.{sample_id}.%s" % (BWA_INDEX_OUTDIR, out) for out in ["amb", "ann", "bwt", "pac", "sa"] ],
    idx_flag = "%s/bwa_index.{assembler}.{sample_id}.flag" % (BWA_INDEX_OUTDIR)
  params:
    idx_base = lambda wildcards: "%s/bwa_index.%s.%s" % (BWA_INDEX_OUTDIR, wildcards.assembler, wildcards.sample_id),
    rule_outdir = BWA_INDEX_OUTDIR
  threads: 4
  shell: """
    bwa index -p {params.idx_base} {input.asm}
    echo "Index Built at `date`" > {output.idx_flag}
  """

###############################################################################
#  ALIGNMENT WRAPPER                                                          #
###############################################################################

def ref_align_wrapper_input(assembler, exp_id):
  dt = expDataType(exp_id)
  if dt == "OXFORD_NANOPORE,SINGLE":
    return  "%s/ont_single.%s.%s.bam" % (__REF_ALIGN_HIDDEN__, assembler, exp_id)
  elif dt == "ILLUMINA,SINGLE":
    return  "%s/illumina_single.%s.%s.bam" % (__REF_ALIGN_HIDDEN__, assembler, exp_id)
  elif dt == "ILLUMINA,PAIRED":
    return  "%s/illumina_paired.%s.%s.bam" % (__REF_ALIGN_HIDDEN__, assembler, exp_id)
  else:
    return __NOCASE__

rule ref_aln_wrapper:
  input:
    bam = lambda wildcards: ref_align_wrapper_input(wildcards.assembler, wildcards.exp)
  output:
    bam = "%s/ref_align.{assembler}.{exp}.bam" % (REF_ALIGN_OUTDIR),
    bai = "%s/ref_align.{assembler}.{exp}.bam.bai" % (REF_ALIGN_OUTDIR)
  shell: """
    ln -s {input.bam} {output.bam}
    samtools index {output.bam}
  """

###############################################################################
#  BWA ALIGN ILLUMINA SINGLE                                                  #
###############################################################################

rule ref_aln_illumina_single:
  input:
    idx = lambda wildcards: "%s/bwa_index.%s.%s.flag" % (BWA_INDEX_OUTDIR, wildcards.assembler, expSampleID(wildcards.exp)),
    r   = lambda wildcards: "%s/illumina_single.%s.fq" % (MERGE_MEASUREMENTS_OUTDIR, wildcards.exp)
  output:
    bam = "%s/illumina_single.{assembler}.{exp}.bam" % __REF_ALIGN_HIDDEN__
  threads: 4
  params:
    sam = lambda wildcards: "%s/illumina_single.%s.%s.sam" % (__REF_ALIGN_HIDDEN__, wildcards.assembler, wildcards.exp),
    idx_base = lambda wildcards: "%s/bwa_index.%s.%s" % (BWA_INDEX_OUTDIR, wildcards.assembler, expSampleID(wildcards.exp)),
    rule_outdir = __REF_ALIGN_HIDDEN__,
  shell: """
    mkdir -p {params.rule_outdir}
    bwa mem -t {threads} {params.idx_base} {input.r} > {params.sam}
    samtools view -u {params.sam} | samtools sort -@ {threads} - -o{output.bam}
  """

###############################################################################
#  BWA ALIGN ILLUMINA PAIRED                                                  #
###############################################################################

rule ref_aln_illumina_paired:
  input:
    idx = lambda wildcards: "%s/bwa_index.%s.%s.flag" % (BWA_INDEX_OUTDIR, wildcards.assembler, expSampleID(wildcards.exp)),
    r1  = lambda wildcards: "%s/illumina_paired.%s_1.fq" % (MERGE_MEASUREMENTS_OUTDIR, wildcards.exp),
    r2  = lambda wildcards: "%s/illumina_paired.%s_2.fq" % (MERGE_MEASUREMENTS_OUTDIR, wildcards.exp)
  output:
    bam = "%s/illumina_paired.{assembler}.{exp}.bam" % __REF_ALIGN_HIDDEN__
  threads: 4
  params:
    sam = lambda wildcards: "%s/illumina_paired.%s.%s.sam" % (__REF_ALIGN_HIDDEN__, wildcards.assembler, wildcards.exp),
    idx_base = lambda wildcards: "%s/bwa_index.%s.%s" % (BWA_INDEX_OUTDIR, wildcards.assembler, expSampleID(wildcards.exp)),
    rule_outdir = __REF_ALIGN_HIDDEN__,
  shell: """
    mkdir -p {params.rule_outdir}
    bwa mem -t {threads} {params.idx_base} {input.r1} {input.r2} > {params.sam}
    samtools view -u {params.sam} | samtools sort -@ {threads} - -o{output.bam}
  """

###############################################################################
#  ALIGN ONT SINGLE                                                           #
###############################################################################

rule ref_aln_ont:
  input:
    idx = lambda wildcards: "%s/bwa_index.%s.%s.flag" % (BWA_INDEX_OUTDIR, wildcards.assembler, expSampleID(wildcards.exp)),
    #asm = lambda wildcards: "%s/asm.%s.%s.fa" % (ASM_OUTDIR, wildcards.assembler, expSampleID(wildcards.exp)),
    ont = lambda wildcards: "%s/ont_single.%s.fq" % (MERGE_MEASUREMENTS_OUTDIR, wildcards.exp)
  output: 
    bam = "%s/ont_single.{assembler}.{exp}.bam" % __REF_ALIGN_HIDDEN__
  threads: 4
  params:
    sam = lambda wildcards: "%s/ont_single.%s.%s.sam" % (__REF_ALIGN_HIDDEN__, wildcards.assembler, wildcards.exp),
    idx_base = lambda wildcards: "%s/bwa_index.%s.%s" % (BWA_INDEX_OUTDIR, wildcards.assembler, expSampleID(wildcards.exp)),
    rule_outdir = __REF_ALIGN_HIDDEN__
  shell: """
    mkdir -p {params.rule_outdir}
    bwa mem -t {threads} -x ont2d {params.idx_base} {input.ont} > {params.sam}
    samtools view -u {params.sam} | samtools sort -@ {threads} - -o{output.bam}
  """
  #graphmap align -t {threads} -r {input.asm} -d {input.ont} -o {params.sam}
