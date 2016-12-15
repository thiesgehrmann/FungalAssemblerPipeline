from ibidas import *

rule augustus:
  input:
    asm = lambda wildcards: "%s/asm.%s.%s.fa" % (ASM_OUTDIR, wildcards.assembler, wildcards.sample_id)
  output:
    gff = "%s/augustus.{assembler}.{sample_id}.gff" % AUGUSTUS_OUTDIR
  threads: 4
  params:
    augustus_species = __AUGUSTUS_SPECIES__
  shell: """
    augustus [parameters] --species={params.augustus_species} {input.asm} > {output.gff}
  """

rule augustus_gff2fasta:
  input:
    gff = lambda wildcards: "%s/augustus.%s.%s.gff" % (ASM_OUTDIR, wildcards.assembler, wildcards.sample_id),
    asm = lambda wildcards: "%s/asm.%s.%s.fa" % (ASM_OUTDIR, wildcards.assembler, wildcards.sample_id)
  output:
    prot_fasta = "%s/augustus.{assembler}.{sample_id}.fa" % AUGUSTUS_OUTDIR
  threads: 1
  run:
    G = Read(input.gff, format="gff")
    S = Read(input.asm, format="fasta")
