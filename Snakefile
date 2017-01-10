# Associated env: test
###############################################################################
#  CONFIGURATION                                                              #
###############################################################################

tconfig = { "assemblers": []}

defaultparams = {
  #Miniasm
  "template" : "miniasm",
  "minimap_params" : "-Sw5 -L100 -m0",

  #Canu
  "template"   : "canu",
  "canu_genomesize" : "12.2m",
  "canu_maxmem"     : "20G",
  "canu_params"     : "corMaxEvidenceErate=0.15 useGrid=false",
  "canu_correct_iter"   : 1,
  "canu_correct_params" : "",
  "canu_trim_params"    : "",
  "canu_assemble_params": "errorRate=0.1 utgGraphDeviation=50",

  # spades
  "template" : "spades",
  "spades_params" : "",

  # Racon
  "racon_do"      : True, # True|False
  "racon_maxiter" : 2, # Int [1-9] HARD UPPER LIMIT: 9

  # Pilon
  "pilon_do"      : True, # Bool, Default: True
  "pilon_maxmem"  : "32g", # String, Default 32g
  "pilon_maxiter" : 2, # Int [1-9] HARD UPPER LIMIT: 9

  # Augustus
  "augustus_species"       : "saccharomyces_cerevisiae_S288C", # Must be specified
  "augustus_params"        : "",
  "augustus_geneid_prefix" : lambda wildcards: wildcards.sample_id, #You should probably leave this alone

  # Busco
  "busco_do"       : True,
  "busco_database" : "http://busco.ezlab.org/datasets/saccharomycetales_odb9.tar.gz", # URL to .tar.gz file

  # Quast
  "quast_do"           : True,
  "quast_ref"          : "/home/thiesgehrmann/data/genomes/yeast_S288C/GCA_000146045.2_R64_genomic.fna",  # String, Default: None
  "quast_gff"          : "/home/thiesgehrmann/data/genomes/yeast_S288C/GCA_000146045.2_R64_genomic.gff",  # String, Default: None
  "quast_eukaryote"    : True,  # Bool, Default: True
  "quast_est_ref_size" : None,  # Int, Default: None
  "quast_scaffolds"    : False, # Bool, Default: False
}

###############################################################################

def addParams(name, d):
  p = defaultparams.copy()
  p.update(d)
  tconfig[name] = p
  tconfig["assemblers"].append(name)


###############################################################################
#  TOOL PARAMETERS                                                            #
###############################################################################

#Miniasm
addParams("miniasm_full",
  {"template" : "miniasm",
   "minimap_params" : "-Sw5 -L100 -m0",
   "miniasm_params" : ""})


addParams("miniasm_noracon",
  {"template" : "miniasm",
   "minimap_params" : "-Sw5 -L100 -m0",
   "miniasm_params" : "",
   "racon_do": False})

addParams("miniasm_nopilon",
  {"template" : "miniasm",
   "minimap_params" : "-Sw5 -L100 -m0",
   "miniasm_params" : "",
   "pilon_do": False})

addParams("miniasm_nopolish",
  {"template" : "miniasm",
   "minimap_params" : "-Sw5 -L100 -m0",
   "miniasm_params" : "",
   "racon_do": False,
   "pilon_do": False})

#Canu parameters
addParams("canu_full",
  {"template"   : "canu",
   "canu_genomesize" : "12.2m",
   "canu_maxmem"     : "20G",
   "canu_params"     : "corMaxEvidenceErate=0.15 useGrid=false stopOnReadQuality=false"})

addParams("canu_noracon",
  {"template"   : "canu",
   "canu_genomesize" : "12.2m",
   "canu_maxmem"     : "20G",
   "canu_params"     : "corMaxEvidenceErate=0.15 useGrid=false stopOnReadQuality=false",
   "racon_do"        : False})

addParams("canu_nopilon",
  {"template"   : "canu",
   "canu_genomesize" : "12.2m",
   "canu_maxmem"     : "20G",
   "canu_params"     : "corMaxEvidenceErate=0.15 useGrid=false stopOnReadQuality=false",
   "pilon_do"        : False})

addParams("canu_nopolish",
  {"template"   : "canu",
   "canu_genomesize" : "12.2m",
   "canu_maxmem"     : "20G",
   "canu_params"     : "corMaxEvidenceErate=0.15 useGrid=false stopOnReadQuality=false",
   "racon_do"        : False,
   "pilon_do"        : False})

addParams("canu_r71d",
  {"template"   : "canu",
   "canu_genomesize" : "12.2m",
   "canu_maxmem"     : "20G",
   "canu_params"     : "corMaxEvidenceErate=0.15 useGrid=false stopOnReadQuality=false",
   "canu_correct_iter"   : 5,
   "canu_correct_params" : "corOutCoverage=500 corMinCoverage=0 corMhapSensitivity=high",
   "canu_trim_params"    : "",
   "canu_assemble_params": "errorRate=0.1 utgGraphDeviation=50"})

addParams("canu_r79mixed_d",
  {"template"   : "canu",
   "canu_genomesize" : "12.2m",
   "canu_maxmem"     : "20G",
   "canu_params"     : "corMaxEvidenceErate=0.15 useGrid=false errorRate=0.025 stopOnReadQuality=false",
   "canu_correct_iter"   : 1,
   "canu_correct_params" : "corMinCoverage=0 errorRate=0.035",
   "canu_trim_params"    : "",
   "canu_assemble_params": ""})

addParams("spades_full",
  {"template" : "spades",
   "quast_scaffolds" : True})

addParams("spades_noracon",
  {"template" : "spades",
   "racon_do" : False,
   "quast_scaffolds" : True})

addParams("spades_nopilon",
  {"template" : "spades",
   "pilon_do" : False,
   "quast_scaffolds" : True})

addParams("spades_nopolish",
  {"template" : "spades",
   "racon_do" : False,
   "pilon_do" : False,
   "quast_scaffolds" : True})

###############################################################################
###############################################################################

###############################################################################
#  DO NOT EDIT BELOW THIS LINE                                                #
###############################################################################

configfile: "config.json"

WORKDIR     = "__WORKDIR_REPLACE__"
INSTALL_DIR = "__INSTALL_DIR_REPLACE__"

include: "%s/pipeline.Snakefile" % INSTALL_DIR
