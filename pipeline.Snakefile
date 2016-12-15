import re

###############################################################################
#  INTERNAL VARIABLES                                                         #
###############################################################################

__NOCASE__ = "/UNDEFINED/CASE/../NO/CURRENT/IMPLEMENTATION"

wildcard_constraints:
  sample_id = "[^./]+",
  assembler = "[^./]+",
  exp       = "[^./]+",
  iter      = "[0-9]"

###############################################################################
#  FUNCTIONS                                                                  #
###############################################################################

uniq = lambda L: list(set(L))
iden = lambda x,y: set(x) == set(y)

sampleExpID_ONTS = lambda sample_id: uniq([ r["experiment_id"] for r in config["data"] if (r["sample_id"] == sample_id and r["data_type"] == "OXFORD_NANOPORE")])
sampleExpID_ILLS = lambda sample_id: uniq([ r["experiment_id"] for r in config["data"] if (r["sample_id"] == sample_id and r["data_type"] == "ILLUMINA" and r["library_layout"] == "SINGLE")])
sampleExpID_ILLP = lambda sample_id: uniq([ r["experiment_id"] for r in config["data"] if (r["sample_id"] == sample_id and r["data_type"] == "ILLUMINA" and r["library_layout"] == "PAIRED")])
sampleExpIDs     = lambda sample_id: uniq([ r["experiment_id"] for r in config["data"] if (r["sample_id"] == sample_id) ])

expDataType      = lambda exp_id: [ "%s,%s" % (r["data_type"], r["library_layout"]) for r in config["data"] if r["experiment_id"] == exp_id][0]
sampleDataTypes  = lambda sample_id: uniq([ "%s,%s" % (r["data_type"], r["library_layout"]) for r in config["data"] if r["sample_id"] == sample_id])

expSampleID = lambda exp_id: [ r["sample_id"] for r in config["data"] if r["experiment_id"] == exp_id][0]

#escapeBraces = lambda s: re.sub(r'({[^{}]+})', r'\{\1\}', s)
escapeBraces = lambda s: s

###############################################################################
#  SHELL FUNCTIONS                                                            #
###############################################################################

cmpFastaSeqs = escapeBraces("""
function cmpFastaSeqs() {
  local f1="$1"
  local f2="$2";

  h1=`cat "$f1" | tr '\\n' '|' | sort | cut -d\| -f2 | tr '[:upper:]' '[:lower:]' | md5sum | head -c 32`
  h2=`cat "$f2" | tr '\\n' '|' | sort | cut -d\| -f2 | tr '[:upper:]' '[:lower:]' | md5sum | head -c 32`

  if [ "$h1" != "$h2" ]; then
    echo "1"
  else
    echo "0"
  fi
}
""")
###############################################################################
#  RULE OUTPUT DIRECTORIES                                                    #
###############################################################################

__LOGS_OUTDIR__ = "%s/logs"% WORKDIR

MERGE_MEASUREMENTS_OUTDIR = "%s/merge_measurements" % WORKDIR

ASM_OUTDIR = "%s/assemblies/" % WORKDIR

REF_ALIGN_OUTDIR = "%s/ref_align" % WORKDIR

RACON_OUTDIR = "%s/racon" % WORKDIR

PILON_OUTDIR = "%s/pilon" % WORKDIR


###############################################################################
#  RULE ALL                                                                   #
###############################################################################

rule all:
  input:
    #single_meas = expand("%s/{exp}.fq" % MERGE_MEASUREMENTS_OUTDIR, rep=SINGLE_REP),
    #paired_meas_r1 = expand("%s/{exp}_R1.fq" % MERGE_MEASUREMENTS_OUTDIR, rep=PAIRED_REP),
    #paired_meas_r2 = expand("%s/{exp}_R2.fq" % MERGE_MEASUREMENTS_OUTDIR, rep=PAIRED_REP)
    #minimap = expand("%s/minimap.{exp}.gz" % MINIMAP_OUTDIR, rep=SINGLE_REP)
    #miniasm = expand("%s/miniasm.{exp}.gfa" % MINIASM_OUTDIR, rep=SINGLE_REP)
    final = expand("%s/pilon.{assembler}.{sample_id}.fa"% PILON_OUTDIR, assembler=ASSEMBLERS, sample_id=config["sample_list"])
  benchmark: "%s/all.{assembler}.{sample_id}" % __LOGS_OUTDIR

###############################################################################
#  MERGE ALL MEASUREMENTS INTO ONE                                            #
###############################################################################
include: "merge_measurements.Snakefile"

###############################################################################
#  MERGE ONT IN SAME SAMPLE                                                   #
###############################################################################

MERGE_SAMPLE_ONTS_OUTDIR = "%s/merge_sample_ont" % WORKDIR
rule merge_sample_onts:
  input:
    onts = lambda wildcards: expand("%s/ont_single.{exp}.fq" % (MERGE_MEASUREMENTS_OUTDIR), exp=sampleExpID_ONTS(wildcards.sample_id))
  output:
    ont = "%s/ont_single.{sample_id}.fq" % MERGE_SAMPLE_ONTS_OUTDIR
  params:
    rule_outdir = MERGE_SAMPLE_ONTS_OUTDIR
  benchmark: "%s/merge_sample_onts.{assembler}.{sample_id}" % __LOGS_OUTDIR
  shell: """
    mkdir -p {params.rule_outdir}
    cat {input.onts} > {output.ont}
  """

###############################################################################
#  ASSEMBLERS                                                                 #
###############################################################################

include: "asm_miniasm.Snakefile"
include: "asm_canu.Snakefile"

###############################################################################
#  ALIGNMENT TO REFERENCE                                                     #
###############################################################################

include: "ref_align.Snakefile"

###############################################################################
#  RACON                                                                      #
###############################################################################

include: "racon.Snakefile"

###############################################################################
#  PILON                                                                      #
###############################################################################

include: "pilon.Snakefile"

###############################################################################
#  NANOPOLISH                                                                 #
###############################################################################

#include: "nanopolish.Snakefile"

###############################################################################
#  AUGUSTUS                                                                   #
###############################################################################

#include: "augustus.Snakefile"

###############################################################################
#  BUSCO & METRICS                                                            #
###############################################################################

#include: "busco.Snakefile"
