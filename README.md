# FungalAssemblerPipeline
A pipeline dedicated to the assembly of fungal genomes with ONT reads, and polishing with ONT and illumina reads.

Currently, the Miniasm, Canu and Spades assemblers are implemented in the pipeline.
Polishing steps can be skipped at will.

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

## Example dataset

You can download a small dataset, assembling the S288C genome using data from [Istace et. al.](https://doi.org/10.1093/gigascience/giw018), and run the pipeline on this.
The following downloads the data, initializes the pipeline, and runs the pipeline:
```shell
./prepare_example.sh
mkdir example_run
yes | ./gen_pipeline.sh example_data/PTSV.tsv example_data example_run
cd example_run
snakemake --cores 20 all
```

## Running your own pipeline
You can initialize your own pipeline with the `gen_pipeline.sh` command.

```shell
  ./gen_pipeline.sh <data_desc> <data_dir> <run_dir>
```
Where data_desc is a file describing the samples and the data they all contain (see [example_data/PTSV.tsv](example_data/PTSV.tsv) for an example).


### Modifying the assembly parameters
In the file [Snakefile](Snakefile), several assemblers are defined.
You can define your own assembly parameters by adding a set of parameters.
In these parameters, you must specify a template assembler to use.
Currently, only miniasm, canu and spades are included in this pipeline, you you must specify one of them:
```python
params = { "template": "miniasm",
           "racon_do": False,
           "pilon_do": True }
addParams("my_first_assembler", params)
```

### Adding assembler templates
You can add assembler templates.
Look at the [pipeline_components/template_template.Snakefile](pipeline_components/template_template.Snakefile) for a template on how to do this.
Also look at [pipeline_components/template_miniasm.Snakefile](pipeline_components/template_miniasm.Snakefile) to see how it is done.

The resulting Snakefile must then be included in (pipeline.Snakefile).

