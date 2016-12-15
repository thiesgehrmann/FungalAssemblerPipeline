###############################################################################
# AUGUSTUS                                                                    #
###############################################################################

rule augustus_gff:
  input:
    asm = lambda wildcards: "%s/asm.%s.%s.fa" % (ASM_OUTDIR, wildcards.assembler, wildcards.sample_id)
  output:
    gff = "%s/augustus.{assembler}.{sample_id}.gff" % AUGUSTUS_OUTDIR
  threads: 4
  params:
    augustus_species = __AUGUSTUS_SPECIES__
    augustus_params  = __AUGUSTUS_PARAMS__
  shell: """
    augustus {params.augustus_params} \
             --gff3=on \
             --genemodel=complete \
             --strand=both  \
             --species={params.augustus_species} \
             {input.asm} \
      | sed -e "s/\([= ]\)\(g[0-9]\+\)/\1$sample_id|\2/g" \
      > {output.gff}
  """

###############################################################################

rule augustus_gff2fasta:
  input:
    gff = lambda wildcards: "%s/augustus.%s.%s.gff" % (ASM_OUTDIR, wildcards.assembler, wildcards.sample_id),
    asm = lambda wildcards: "%s/asm.%s.%s.fa" % (ASM_OUTDIR, wildcards.assembler, wildcards.sample_id)
  output:
    prot_fasta = "%s/augustus.{assembler}.{sample_id}.fa" % AUGUSTUS_OUTDIR
  threads: 1
  shell: """
    cat { input.gff} \
     | grep "^# " \
     | tr -d '#' \
     | awk 'BEGIN{ BUF=""; IN=0}
           {if(index($0,"start") != 0){ 
              IN=1;
            }
            if ( IN == 1){
              BUF=BUF $0
              if( index($0, "end") != 0) {
                print BUF
                BUF=""
              }
            }}' \
     | sed -e 's/[ ]*start gene \([^ ]\+\) protein sequence = \[\([A-Za-z ]\+\)\] end gene.*/>\1\n\2/' \
     | tr -d ' ' \
     | fold -w80 \
     > {output.prot_fasta}
  """

