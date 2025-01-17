#!/bin/bash

# for unzipping fastq files
gunzip *.fastq.gz

# Manifest file (for only forward reads)
echo -e "sample-id\tabsolute-filepath" > single-end-manifest.tsv

for f in $(ls *_1.fastq); do sample_id=$(basename $f _1.fastq) echo -e "$sample_id\t$PWD/$f" done >> single-end-manifest.tsv


# Demux
# For forward sequence-reads only
qiime tools import \
--type 'SampleData[SequencesWithQuality]' \
--input-path single-end-manifest.csv \
--output-path single-end-demux.qza \
--input-format SingleEndFastqManifestPhred33V2

# Demux summary
qiime demux summarize\
--i-data single-end-demux.qza \
--o-visualization demux.qzv

# Quality filtering
qiime dada2 denoise-single \ 
--i-demultiplexed-seqs demux.qza \
--p-trim-left 0 \
 --p-trunc-len 130 \
--o-table table-dada2.qza \
 --o-denoising-stats denoising-stats.qza \
 --o-representative-sequences rep-seqs-dada2.qza \ 

 # Assign taxonomy
 qiime feature-classifier classify-sklearn \
  --i-classifier silva-138-99-nb-classifier.qza \
  --i-reads rep-seqs-dada2.qza \
  --o-classification taxonomy.qza

# Taxonomy visualization
 qiime taxa barplot \
  --i-table table-dada2.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file metadata.tsv \
  --o-visualization taxa-bar-plots.qzv

  # Generate a tree for phylogenetic diversity analysis
 qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs-dada2.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza

  # Differential abundance testing

 qiime composition add-pseudocount \ --i-table table.qza \ --o-composition-table comp-table.qza
 qiime composition ancom \ --i-table comp-table.qza \ --m-metadata-file sample-metadata.tsv \ --m-metadata-column group-column \ --o-visualization ancom-group.qzv


 qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs-dada2.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza


 qiime composition add-pseudocount \
  --i-table table-dada2.qza \
  --o-composition-table comp-table.qza

 qiime composition ancom \
  --i-table comp-table.qza \
  --m-metadata-file metadata.tsv \
  --m-metadata-column group \
  --o-visualization ancom-group.qzv


 qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted-tree.qza \
  --i-table table-dada2.qza \
  --p-sampling-depth 1000 \
  --m-metadata-file metadata.tsv \
  --output-dir core-metrics-results

 qiime diversity beta-group-significance \
  --i-distance-matrix weighted_unifrac_distance_matrix.qza \
  --m-metadata-file metadata.tsv \
  --m-metadata-column group \
  --o-visualization weighted-unifrac-environmental-variable-significance.qzv






