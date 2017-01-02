###############################################################################
# AUGUSTUS                                                                    #
###############################################################################

rule augustus_gff:
  input:
    asm = lambda wildcards: "%s/pilon.%s.%s.fa" % (PILON_OUTDIR, wildcards.assembler, wildcards.sample_id)
  output:
    gff = "%s/augustus_gff.{assembler}.{sample_id}.gff" % AUGUSTUS_OUTDIR
  threads: 4
  params:
    augustus_species = lambda wildcards: tconfig[wildcards.assembler]["augustus_species"],
    augustus_params  = lambda wildcards: tconfig[wildcards.assembler]["augustus_params"],
    rule_outdir = AUGUSTUS_OUTDIR
  benchmark: "%s/augustus_gff.{assembler}.{sample_id}" % __LOGS_OUTDIR__
  shell: """
    mkdir -p {params.rule_outdir}
    augustus {params.augustus_params} \
             --gff3=on \
             --genemodel=complete \
             --strand=both  \
             --species={params.augustus_species} \
             {input.asm} \
      > {output.gff}
  """

###############################################################################

rule augustus_gff_sample:
  input:
    gff = lambda wildcards: "%s/augustus_gff.%s.%s.gff" % (AUGUSTUS_OUTDIR, wildcards.assembler, wildcards.sample_id)
  output:
    gff = "%s/augustus.{assembler}.{sample_id}.gff" % AUGUSTUS_OUTDIR
  params:
    geneid_prefix = lambda wildcards: tconfig[wildcards.assembler]["augustus_geneid_prefix"](wildcards)
  shell: """
    sed -e "s/\([= ]\)\(g[0-9]\+\)/\\1{params.geneid_prefix}|\\2/g" {input.gff} > {output.gff}
  """

###############################################################################

rule augustus_gff2fasta:
  input:
    gff = lambda wildcards: "%s/augustus.%s.%s.gff" % (AUGUSTUS_OUTDIR, wildcards.assembler, wildcards.sample_id)
  output:
    prot_fasta = "%s/augustus.{assembler}.{sample_id}.fa" % AUGUSTUS_OUTDIR
  threads: 1
  benchmark: "%s/augustus_gff2fasta.{assembler}.{sample_id}" % __LOGS_OUTDIR__
  shell: """
    cat {input.gff} \
     | grep "^# " \
     | tr -d '#' \
     | grep -v -e "[pP]redict" -e "----" -e "(none)" \
     | awk 'BEGIN{{ BUF=""; IN=0}}
           {{if(index($0,"start") != 0){{ 
              IN=1;
            }}
            if ( IN == 1){{
              BUF=BUF $0
              if( index($0, "end") != 0) {{
                print BUF
                BUF=""
              }}
            }}}}' \
     | sed -e 's/^[ ]*start gene \([^ ]\+\) protein sequence = \[\([A-Za-z ]\+\)\] end gene.*$/>\\1\\n\\2/' \
     | tr -d ' ' \
     | fold -w80 \
     > {output.prot_fasta}
  """

