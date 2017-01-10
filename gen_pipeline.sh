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

function readWhileInvalidChar(){

  validchars="$1"
  while true; do
    read -n1 -p "($validchars): " c
    if [[ "$validchars" == *"$c"* ]]; then
      echo $c;
      break;
    fi
  done
}

###############################################################################

function verifyOverWrite(){
  local file="$1";

  if [ -e "$file" ]; then
    warning "The file $file already exists, are you sure you want to overwrite it?"
    resp=`readWhileInvalidChar yn`
    echo ""
    if [ "$resp" == "n" ]; then
      error "File cannot be overwritten"
      exit 1
    fi
  fi
}


###############################################################################

function usage(){
  cmd="$1";

  echo "Usage: $cmd <data_desc.tsv> <data_dir> <out_dir>"
  echo ""
  echo "  data_desc.tsv: A TSV file describing the data (see example), with"
  echo "                 relative paths to data files. I.e. if the tsv file"
  echo "                 is in the same directory, it should just be the name."
  echo "  data_dir:      The full path prefix of the data"
  echo "  out_dir:       There the pipeline and all its data will reside"
}


###############################################################################

if [ $# -ne 3 ]; then
  usage $0
  exit 1
fi

data_desc="$1";
data_dir="$2";
out_dir="$3";

###############################################################################

mkdir -p "$out_dir"


# Download the conversion tool if we need it
if [ ! -e "$SCRIPTDIR/pipeline_tools/pipelinetsv2PipelineJSON.py" ]; then
  wget https://raw.githubusercontent.com/thiesgehrmann/bioscripts/master/pipelinetsv2pipelineJSON.py -O "$SCRIPTDIR/pipeline_tools/pipelinetsv2PipelineJSON.py" &> /dev/null
  chmod +x "$SCRIPTDIR/pipeline_tools/pipelinetsv2PipelineJSON.py"
fi


###############################################################################


  # Generate config file
verifyOverWrite $out_dir/config.json
"$SCRIPTDIR/pipeline_tools/pipelinetsv2PipelineJSON.py" $data_desc $data_dir > $out_dir/config.json

###############################################################################

  # Copy Snakefile to proper directory
verifyOverWrite "$out_dir/Snakefile"
cat "$SCRIPTDIR/Snakefile" \
  | sed -e "s!__INSTALL_DIR_REPLACE__!$SCRIPTDIR!" \
        -e "s!__WORKDIR_REPLACE__!$out_dir!" \
  > "$out_dir/Snakefile"

###############################################################################

echo "Pipeline initialized in $out_dir."
echo "Data configuration is in $out_dir/config.json"
echo "Change the necessary parameters in $out_dir/Snakefile"

