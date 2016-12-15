###############################################################################
#  PILON                                                                      #
###############################################################################

rule pilon_begin:
  input:
    asm = lambda wildcards: "%s/asm.%s.%s.fa" % (ASM_OUTDIR, wildcards.assembler, wildcards.sample_id)
  output:
    asm = "%s/pilon.{assembler}.{sample_id}/asm.0.fa" % PILON_OUTDIR
  params:
    tmp_outdir = lambda wildcards: "%s/pilon.%s.%s" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id)
  benchmark: "%s/pilon_begin.{assembler}.{sample_id}" % __LOGS_OUTDIR__
  shell: """
    mkdir -p {params.tmp_outdir}
    cp {input.asm} {output.asm}
  """

###############################################################################

rule pilon_end:
  input:
    asm = lambda wildcards: expand("%s/pilon.%s.%s/asm.{iter}.fa" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id), iter=range(1, __PILON_MAX_ITER__ + 1))
  output:
    asm = "%s/pilon.{assembler}.{sample_id}.fa" % (PILON_OUTDIR)
  params:
    final_asm = lambda wildcards: "%s/pilon.%s.%s/asm.%d.fa" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id, __RACON_MAX_ITER__)
  benchmark: "%s/pilon_end.{assembler}.{sample_id}" % __LOGS_OUTDIR__
  shell: """
    cp {params.final_asm} {output.asm}
  """

###############################################################################

rule pilon_iter_bwa_build:
  input:
    asm = lambda wildcards: "%s/pilon.%s.%s/asm.%d.fa" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id, int(wildcards.iter))
  output:
    index = ["%s/pilon.{assembler}.{sample_id}/idx.{iter,[0-9]}.%s" % (PILON_OUTDIR, out) for out in ["amb", "ann", "bwt", "pac", "sa"] ],
    idx_flag = "%s/pilon.{assembler}.{sample_id}/idx.{iter,[0-9]}.flag" % (PILON_OUTDIR)
  params:
    idx_base = lambda wildcards: "%s/pilon.%s.%s/idx.%d" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id, int(wildcards.iter)),
    rule_outdir = BWA_INDEX_OUTDIR
  threads: 4
  benchmark: "%s/pilon_iter_bwa_build.{assembler}.{sample_id}.{iter}" % __LOGS_OUTDIR__
  shell: """
    bwa index -p {params.idx_base} {input.asm}
    echo "Index Built at `date`" > {output.idx_flag}
  """

###############################################################################

rule pilon_iter_align_single:
  input:
    asm  = lambda wildcards: "%s/pilon.%s.%s/asm.%d.fa" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id, int(wildcards.iter)),
    flag = lambda wildcards: "%s/pilon.%s.%s/idx.%d.flag" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id, int(wildcards.iter)),
    r    = lambda wildcards: "%s/illumina_single.%s.fq" % (MERGE_MEASUREMENTS_OUTDIR, wildcards.exp)
  output:
    bam = "%s/pilon.{assembler}.{sample_id}/illumina_single.{exp}.{iter,[0-9]}.bam" % PILON_OUTDIR,
  threads: 4
  params:
    sam      = lambda wildcards: "%s/pilon.%s.%s/illumina_single.%s.%d.bam" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id, wildcards.exp, int(wildcards.iter)),
    idx_base = lambda wildcards: "%s/pilon.%s.%s/idx.%d" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id, int(wildcards.iter))
  benchmark: "%s/pilon_iter_align_single.{assembler}.{sample_id}.{exp}.{iter}" % __LOGS_OUTDIR__
  shell: """
    bwa mem -t {threads} {params.idx_base} {input.r} > {params.sam}
    samtools view -u {params.sam} | samtools sort -@ {threads} - -o{output.bam}
  """

###############################################################################

rule pilon_iter_align_paired:
  input:
    asm = lambda wildcards: "%s/pilon.%s.%s/asm.%d.fa" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id, int(wildcards.iter)),
    flag = lambda wildcards: "%s/pilon.%s.%s/idx.%d.flag" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id, int(wildcards.iter)),
    r1   = lambda wildcards: "%s/illumina_paired.%s_1.fq" % (MERGE_MEASUREMENTS_OUTDIR, wildcards.exp),
    r2   = lambda wildcards: "%s/illumina_paired.%s_2.fq" % (MERGE_MEASUREMENTS_OUTDIR, wildcards.exp)
  output:
    bam = "%s/pilon.{assembler}.{sample_id}/illumina_paired.{exp}.{iter,[0-9]}.bam" % PILON_OUTDIR,
  threads: 4
  params:
    sam      = lambda wildcards: "%s/pilon.%s.%s/illumina_paired.%s.%d.bam" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id, wildcards.exp, int(wildcards.iter)),
    idx_base = lambda wildcards: "%s/pilon.%s.%s/idx.%d" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id, int(wildcards.iter))
  benchmark: "%s/pilon_iter_align_paired.{assembler}.{sample_id}.{exp}.{iter}" % __LOGS_OUTDIR__
  shell: """
    bwa mem -t {threads} {params.idx_base} {input.r1} {input.r2} > {params.sam}
    samtools view -u {params.sam} | samtools sort -@ {threads} - -o{output.bam}
  """

###############################################################################

def pilon_iter_align_wrapper_input(assembler, sample_id, exp_id, iter):
  dt = expDataType(exp_id)
  if dt == "ILLUMINA,SINGLE":
    return  "%s/pilon.%s.%s/illumina_single.%s.%d.bam" % (PILON_OUTDIR, assembler, sample_id, exp_id, int(iter))
  elif dt == "ILLUMINA,PAIRED":
    return  "%s/pilon.%s.%s/illumina_paired.%s.%d.bam" % (PILON_OUTDIR, assembler, sample_id, exp_id, int(iter))
  else:
    return __NOCASE__

###############################################################################

rule pilon_iter_align_wrapper:
  input:
    bam = lambda wildcards: pilon_iter_align_wrapper_input(wildcards.assembler, wildcards.sample_id, wildcards.exp, wildcards.iter)
  output:
    bam = "%s/pilon.{assembler}.{sample_id}/aln.{exp}.{iter,[0-9]}.bam" % (PILON_OUTDIR),
    bai = "%s/pilon.{assembler}.{sample_id}/aln.{exp}.{iter,[0-9]}.bam.bai" % (PILON_OUTDIR)
  benchmark: "%s/pilon_iter_align_wrapper.{assembler}.{sample_id}.{exp}.{iter}" % __LOGS_OUTDIR__
  shell: """
    ln -s {input.bam} {output.bam}
    samtools index {output.bam}
  """

###############################################################################

rule pilon_iter_polish:
  input:
    asm = lambda wildcards: "%s/pilon.%s.%s/asm.%d.fa"  % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id, int(wildcards.iter) - 1),
    bam = lambda wildcards: expand("%s/pilon.%s.%s/aln.{exp}.%d.bam" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id, int(wildcards.iter) - 1), exp=(sampleExpID_ILLS(wildcards.sample_id) + sampleExpID_ILLP(wildcards.sample_id))),
  output:
    asm = "%s/pilon.{assembler}.{sample_id}/asm.{iter,[1-9]}.fa" % PILON_OUTDIR
  threads: 4
  params:
    assembler = lambda wildcards: wildcards.assembler,
    sample_id = lambda wildcards: wildcards.sample_id,
    tmp_outdir = lambda wildcards: "%s/pilon.%s.%s" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id),
    iter       = lambda wildcards: int(wildcards.iter),
    max_iter   = __PILON_MAX_ITER__,
    pilon_maxmem = __PILON_MAXMEM__,
    cmpFastaSeqs = cmpFastaSeqs,
    ills_fmt = lambda wildcards: ' '.join(["--unpaired %s/pilon.%s.%s/aln.%s.%d.bam" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id, exp, int(wildcards.iter) - 1) for exp in sampleExpID_ILLS(wildcards.sample_id) ]),
    illp_fmt = lambda wildcards: ' '.join(["--frags    %s/pilon.%s.%s/aln.%s.%d.bam" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id, exp, int(wildcards.iter) - 1) for exp in sampleExpID_ILLP(wildcards.sample_id) ])
  benchmark: "%s/pilon_iter_polish.{assembler}.{sample_id}.{iter}" % __LOGS_OUTDIR__
  shell: """
   {params.cmpFastaSeqs}
    pilon "-Xmx{params.pilon_maxmem}"  --threads {threads} --outdir {params.tmp_outdir} --output pilon.{params.iter} --changes --vcf --tracks --genome {input.asm} {params.ills_fmt} {params.illp_fmt}
    cp {params.tmp_outdir}/pilon.{params.iter}.fasta {output.asm}

   if [ {params.iter} -lt {params.max_iter} ] && [ `cmpFastaSeqs {output.asm} {params.tmp_outdir}/$(({params.iter}-1)).fa` == "0" ]; then
     for i in `seq {params.iter}; do
       cp {output.asm} {params.tmp_outdir}/asm.$i.fa 
     done
   fi 
  """

