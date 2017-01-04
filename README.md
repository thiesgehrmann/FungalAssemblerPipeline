# FungalAssemblerPipeline
A pipeline dedicated to the assembly of fungal genomes with ONT reads, and polishing with ONT and illumina reads.

![A graphical representation of the pipeline](/rulegraph.png)

## Dependencies

  * Assemblers (At least one):
    * Miniasm
    * Canu
    * Spades
  * Polishing (At least one):
    * Racon
      * Minimap
    * Pilon
  * Metrics (At least one):
    * BUSCO
      * Augustus
    * QUAST
  * Core tools
    * bwa
    * Samtools
    * Pandas
