###############################################################################
# cmpFastaSeqs                                                                #
#  Compare the FASTA sequences of two fasta files, ignoring case and headers  #
###############################################################################


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

