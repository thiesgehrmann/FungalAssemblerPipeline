import re

###############################################################################
#  INTERNAL VARIABLES                                                         #
###############################################################################

__ASSEMBLERS__ = tconfig["assemblers"]

__TOOLS_DIR__   = "%s/pipeline_tools" % INSTALL_DIR
__COMP_DIR__    = "pipeline_components"


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
flat = lambda x: [ item for list in x for item in list ]

sampleExpID_ONTS       = lambda sample_id: uniq([ r["experiment_id"] for r in config["data"] if (r["sample_id"] == sample_id and r["data_type"] == "OXFORD_NANOPORE")])
sampleExpID_ONTS_R7_1D = lambda sample_id: uniq([ r["experiment_id"] for r in config["data"] if (r["sample_id"] == sample_id and r["data_type"] == "OXFORD_NANOPORE" and r["library_layout"] == "r71d")])
sampleExpID_ONTS_R7_2D = lambda sample_id: uniq([ r["experiment_id"] for r in config["data"] if (r["sample_id"] == sample_id and r["data_type"] == "OXFORD_NANOPORE" and r["library_layout"] == "r72d")])
sampleExpID_ONTS_R9_1D = lambda sample_id: uniq([ r["experiment_id"] for r in config["data"] if (r["sample_id"] == sample_id and r["data_type"] == "OXFORD_NANOPORE" and r["library_layout"] == "r91d")])
sampleExpID_ONTS_R9_2D = lambda sample_id: uniq([ r["experiment_id"] for r in config["data"] if (r["sample_id"] == sample_id and r["data_type"] == "OXFORD_NANOPORE" and r["library_layout"] == "r92d")])


sampleExpID_ILLS = lambda sample_id: uniq([ r["experiment_id"] for r in config["data"] if (r["sample_id"] == sample_id and r["data_type"] == "ILLUMINA" and r["library_layout"] == "SINGLE")])
sampleExpID_ILLP = lambda sample_id: uniq([ r["experiment_id"] for r in config["data"] if (r["sample_id"] == sample_id and r["data_type"] == "ILLUMINA" and r["library_layout"] == "PAIRED")])
sampleExpIDs     = lambda sample_id: uniq([ r["experiment_id"] for r in config["data"] if (r["sample_id"] == sample_id) ])

expIDs = [ item for list in config["data"] for item in list ]

expDataType      = lambda exp_id: [ "%s,%s" % (r["data_type"], r["library_layout"]) for r in config["data"] if r["experiment_id"] == exp_id][0]
sampleDataTypes  = lambda sample_id: uniq([ "%s,%s" % (r["data_type"], r["library_layout"]) for r in config["data"] if r["sample_id"] == sample_id])

expSampleID = lambda exp_id: [ r["sample_id"] for r in config["data"] if r["experiment_id"] == exp_id][0]

###############################################################################
#  SHELL FUNCTIONS                                                            #
###############################################################################

__SHELL_FUNCTIONS__ = "%s/shell_functions.sh" % __TOOLS_DIR__

###############################################################################
#  RULE OUTPUT DIRECTORIES                                                    #
###############################################################################

__LOGS_OUTDIR__ = "%s/logs"% WORKDIR

FASTQC_OUTDIR = "%s/fastqc" % WORKDIR

MERGE_MEASUREMENTS_OUTDIR = "%s/merge_measurements" % WORKDIR

MERGE_SAMPLE_ONTS_OUTDIR = "%s/merge_sample_ont" % WORKDIR

ASM_OUTDIR = "%s/assemblies/" % WORKDIR

REF_ALIGN_OUTDIR = "%s/ref_align" % WORKDIR

RACON_OUTDIR = "%s/racon" % WORKDIR

PILON_OUTDIR = "%s/pilon" % WORKDIR

AUGUSTUS_OUTDIR = "%s/augustus"% WORKDIR

BUSCO_OUTDIR = "%s/busco" % WORKDIR

QUAST_OUTDIR = "%s/quast" % WORKDIR

METRICS_OUTDIR = "%s/metrics" % WORKDIR

###############################################################################
#  RULE ALL                                                                   #
###############################################################################

rule all:
  input:
    metric = "%s/metrics.tsv" % METRICS_OUTDIR
  benchmark: "%s/all" % __LOGS_OUTDIR__

###############################################################################
#  MERGE ALL MEASUREMENTS INTO ONE                                            #
###############################################################################
include: "%s/merge_measurements.Snakefile" % __COMP_DIR__

###############################################################################
#  MERGE ONT IN SAME SAMPLE                                                   #
###############################################################################

include: "%s/merge_sample_onts.Snakefile" % __COMP_DIR__

###############################################################################
#  ASSEMBLERS                                                                 #
###############################################################################

include: "%s/template_miniasm.Snakefile" % __COMP_DIR__
include: "%s/template_canu.Snakefile" % __COMP_DIR__
include: "%s/template_spades.Snakefile" % __COMP_DIR__

###############################################################################
#  RACON                                                                      #
###############################################################################

include: "%s/racon.Snakefile" % __COMP_DIR__

###############################################################################
#  PILON                                                                      #
###############################################################################

include: "%s/pilon.Snakefile" % __COMP_DIR__

###############################################################################
#  AUGUSTUS                                                                   #
###############################################################################

include: "%s/augustus.Snakefile" % __COMP_DIR__

###############################################################################
#  METRICS                                                                    #
###############################################################################

include: "%s/busco.Snakefile" % __COMP_DIR__
include: "%s/quast.Snakefile" % __COMP_DIR__
include: "%s/metrics.Snakefile" % __COMP_DIR__
