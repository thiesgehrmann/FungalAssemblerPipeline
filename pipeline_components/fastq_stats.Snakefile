rule fastq_stats:
  input:
    fq

  output:
    tsv

  shell: """
    awk '
      BEGIN{
        L=0;
        N=0;
        L_min=100000;
        L_max=0;
      }{
        if(NR%4==2){
          L+=length($0);
          N+=1
          L_min=min(L_min,length($0))
          L_max=max(L_max,length($0))
        }
      }
      END{print L, N, L_min, L_max, L/N}'
