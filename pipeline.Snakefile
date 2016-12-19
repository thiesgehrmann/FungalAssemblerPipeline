import re

###############################################################################
#  INTERNAL VARIABLES                                                         #
###############################################################################

__ASSEMBLERS__ = tconfig["assemblers"].keys()

__TOOLS_DIR__   = "%s/tools" % INSTALL_DIR

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

###############################################################################
#  SHELL FUNCTIONS                                                            #
###############################################################################

__SHELL_FUNCTIONS__ = "%s/tools/shell_functions.sh" % __TOOLS_DIR__

###############################################################################
#  RULE OUTPUT DIRECTORIES                                                    #
###############################################################################

__LOGS_OUTDIR__ = "%s/logs"% WORKDIR

MERGE_MEASUREMENTS_OUTDIR = "%s/merge_measurements" % WORKDIR

MERGE_SAMPLE_ONTS_OUTDIR = "%s/merge_sample_ont" % WORKDIR

ASM_OUTDIR = "%s/assemblies/" % WORKDIR

REF_ALIGN_OUTDIR = "%s/ref_align" % WORKDIR

RACON_OUTDIR = "%s/racon" % WORKDIR

PILON_OUTDIR = "%s/pilon" % WORKDIR

AUGUSTUS_OUTDIR = "%s/augustus"% WORKDIR

BUSCO_OUTDIR = "%s/busco" % WORKDIR

###############################################################################
#  RULE ALL                                                                   #
###############################################################################

rule all:
  input:
    final = expand("%s/busco.{assembler}.{sample_id}.summary"% BUSCO_OUTDIR, assembler=__ASSEMBLERS__, sample_id=config["sample_list"])
  benchmark: "%s/all" % __LOGS_OUTDIR__

###############################################################################
#  MERGE ALL MEASUREMENTS INTO ONE                                            #
###############################################################################
include: "merge_measurements.Snakefile"

###############################################################################
#  MERGE ONT IN SAME SAMPLE                                                   #
###############################################################################

include: "merge_sample_onts.Snakefile"

###############################################################################
#  ASSEMBLERS                                                                 #
###############################################################################

include: "template_miniasm.Snakefile"
include: "template_canu.Snakefile"

###############################################################################
#  ALIGNMENT TO REFERENCE                                                     #
###############################################################################

#include: "ref_align.Snakefile"

###############################################################################
#  RACON                                                                      #
###############################################################################

include: "racon.Snakefile"

###############################################################################
#  PILON                                                                      #
###############################################################################

include: "pilon.Snakefile"

###############################################################################
#  AUGUSTUS                                                                   #
###############################################################################

include: "augustus.Snakefile"

###############################################################################
#  BUSCO & METRICS                                                            #
###############################################################################

include: "busco.Snakefile"
#include: "metrics.Snakefile"
