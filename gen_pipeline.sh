#!/bin/sh

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

###############################################################################

function error() {
  local msg="$1"
  echo "ERROR: $msg"
}

###############################################################################

function warning() {
  local msg="$1"
  echo "WARNING: $msg"
}


###############################################################################

data_desc="$1";
data_dir="$2";
out_dir="$3";
task_name="$4";

mkdir -p "$out_dir"
~/repos/bioscripts/pipelinetsv2pipelineJSON.py $data_desc $data_dir > $out_dir/config.json
find $SCRIPTDIR/ | grep "Snakefile$" | xargs -i cp {} $out_dir
find $out_dir \
  | grep "Snakefile$" \
  | xargs -i sed -i.bak \
      -e "s!__WORKDIR_REPLACE__!$out_dir!" \
      -e "s!__TASKNAME_REPLACE__!$task_name!" {}

find $out_dir \
  | grep "Snakefile.bak$" \
  | xargs rm
