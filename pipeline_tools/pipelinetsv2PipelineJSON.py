#!/usr/bin/env python2

import os;
from ibidas import *
import json

###############################################################################

def tsv2PipelineDict(TSV, dir):

  D = {}

  D["project_list"]     = TSV.project_id.Unique()().tolist()
  D["sample_list"]      = TSV.sample_id.Unique()().tolist()
  D["experiment_list"]   = TSV.experiment_id.Unique()().tolist()
  D["measurement_list"] = TSV.measurement_id.Unique()().tolist()
  D["data_types"]       = TSV.data_type.Unique()().tolist()

  data = []
  for row in zip(*TSV()):
    row_dict = dict(zip(TSV.Names, row))
    if row_dict["library_layout"] == 'SINGLE':
      row_dict["r"] = "%s/%s" % (dir, row_dict["r"])
    else:
      row_dict["r1"] = "%s/%s" % (dir, row_dict["r1"])
      row_dict["r2"] = "%s/%s" % (dir, row_dict["r2"])
    #fi
    data.append(row_dict)
  #efor

  D["data"] = data

  return D
#edef

###############################################################################

###############################################################################

tsv_file = os.sys.argv[1];
location_dir = os.sys.argv[2];

#######################################################

TSV  = Read(tsv_file, delimiter="\t", format="tsv2")
DICT = tsv2PipelineDict(TSV, location_dir)
JSON = json.dumps(DICT, indent=3, sort_keys=True)

print JSON

