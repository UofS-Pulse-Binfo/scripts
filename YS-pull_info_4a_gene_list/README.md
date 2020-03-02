# Yichao's Script
For a given gene list, this script will pull out gene information from multiple GFF3 files and output an customized file.

## Command
```
perl pull_out_genes_from_gff3.pl your_gene_list.txt wanted_organism_genes.gff3 orthologs_1.gff3 orthologs_2.gff3 output_file_name
```
### Parameters
 - your_gene_list.txt: list of genes user wants to pull out
 - wanted_organism_genes.gff3:
 - orthologs_1.gff3:
 - orthologs_2.gff3:
 - output_file_name: expected output file name, no extension


### Restrictions
 - Medicago and Soybean organism names are hard coded in script.

 - Verbose terminal test outputs
