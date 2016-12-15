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

# Download the conversion tool if we need it

if [ ! -e "$SCRIPTDIR/tools/pipelinetsv2PipelineJSON.py" ]; then
  wget https://raw.githubusercontent.com/thiesgehrmann/bioscripts/master/pipelinetsv2pipelineJSON.py -O "$SCRIPTDIR/tools/pipelinetsv2PipelineJSON.py"
  chmod +x "$SCRIPTDIR/tools/pipelinetsv2PipelineJSON.py"
fi


###############################################################################

data_desc="$1";
data_dir="$2";
out_dir="$3";
task_name="$4";

###############################################################################

mkdir -p "$out_dir"

  # Generate config file
"$SCRIPTDIR/tools/pipelinetsv2PipelineJSON.py" $data_desc $data_dir > $out_dir/config.json

  # Copy Snakefile to proper directory
cat "$SCRIPTDIR/Snakefile" \
  | sed -e "s!__INSTALL_DIR_REPLACE__!$SCRIPTDIR!" \
        -e "s!__WORKDIR_REPLACE__!$out_dir!" \
        -e "s!__TASKNAME_REPLACE__!$task_name!" > "$out_dir/Snakefile"

