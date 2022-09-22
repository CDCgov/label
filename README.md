# LABEL, Lineage Assignment by Extended Learning

*By: Sam Shepard (vfn4@cdc.gov), CDC/NCIRD*

LABEL’s purpose is to quickly, automatically, and correctly assign clades or lineages to nucleotide sequences.  Automated lineage assignment has applications in surveillance, research, and high-throughput database annotation.  Currently LABEL supports the lineage assignment of hemagglutinins for influenza A subtypes H5N1 and H9N2. Additional information is on the [LABEL website](https://wonder.cdc.gov/amd/flu/label/).

## METHOD

Lineage Assignment By Extended Learning (LABEL) uses hidden Markov model (HMM) profiles of clade alignments--or groups of clades--to analyze query sequences and then classify them via machine learning techniques. The HMM scoring step is performed via SAM v3.5 (see [*compbio.soe.ucsc.edu/sam.html*](http://compbio.soe.ucsc.edu/sam.html) for more). Prediction is performed hierarchically--usually starting out at a more general level (e.g., a groups of clades) and going to a very specific terminal level (a particular clade). This roughly corresponds to the hierarchical structure of phylogenetic trees and the H5N1 nomenclature system. The prediction phase of LABEL is done via support vector machines (SVM) using the free SHOGUN Machine Learning Toolbox v1.1.0 (multi-class GMNP SVM with polynomial kernel of degree 20, *www.shogun-toolbox.org*). Optional sequence alignment (MUSCLE v3.8.31, see [*www.drive5.com/muscle*](http://www.drive5.com/mus); MAFFT if available, see [mafft.cbrc.jp/alignment/software](http://mafft.cbrc.jp/alignment/software); or via SAM's *align2model* program) and tree-building functions are available to validate LABEL’s predictions  (GTR+GAMMA, 1000 local support bootstraps, maximum-likelihood tree using FastTreeMP v2.1.4, see [*www.microbesonline.org/fasttree*](http://www.microbesonline.org/fasttree)).

## BROADER IMPACT

Although we have only constructed modules for H5 and H9, LABEL's methodology need not be limited to influenza A or even just viral sequences.  Given any phylogenetic tree with defined families or clades, one can train a LABEL module for automated lineage assignment.  Training is performed using a combination of support scripts and by manually applied expert knowledge.

## ACCURACY & PERFORMANCE

On H5v2011 and H9v2011 full length sequences LABEL performs with 100% accuracy on tested datasets and runtime scales linearly at about a half-second per hemagglutinin sequence for a four core machine.  Full results are in pre-publication drafting and available upon request.  Choosing alignment options may increase the runtime significantly; however, guide sequence libraries are never more than 200 sequences in size.  For the best results using the alignment options, break down your query sequence file into smaller files.

## USAGE

```{bash}
Usage:
    LABEL [-P MAX_PROC] [-E C_OPT] [-W WRK_PATH|-O OUT_PATH] [-G|-TACRD|-S] [-L LIN_PATH] <nts.fasta> <project> <Module:H5,H9,etc.>
        -T  Do TRAINING again instead of using classifier files.
        -A  Do ALIGNMENT of re-annotated fasta file (sorted by clade) & build its ML tree.
        -C  Do CONTROL alignment & ML tree construction.
        -E  SGE clustering option. Use 1 or 2 for SGE with array jobs, else local.
        -R  No RECURSIVE prediction. Limits scope, useful with -L option.
        -D  No DELETION of extra intermediary files.
        -S  Show available protein modules.
        -W  Web-server mode: requires ABSOLUTE path to WRITABLE working directory.
        -O  Output directory path, do not use with web mode.
        -G  Create a scoring matrix using given header annotations for Graphing. (removed)
Example: ./LABEL -C gisaid_H5N1.fa Bird_Flu H5
```

## DATA.

- LABEL takes FASTA formatted nucleotide sequences.  The FASTA may be single or multi-line and may contain any number of sequences.  Extra sequences with redundant headers are removed (first-read, first kept)!  Commas and apostrophes are removed from headers while internal spaces are underlined.

- LABEL generates re-annotated FASTA sequences, scoring data, Newick files, alignments, tab-delimited files, and miscellaneous text files.  LABEL's output is limited to text and creates no binaries or images. LABEL's output is limited to a specified output directory (or to a default working directory within the package) and to the current working directory of the calling user.

## FILES GENERATED

| File                       | Type      | Description                                                                 |
| :------------------------- | :-------- | :-------------------------------------------------------------------------- |
| PROJ_final.tab             | Standard. | Tab-delimited headers & predicted clades.                                   |
| PROJ_final.txt             | Standard. | A prettier output of the above.                                             |
| LEVEL_trace.tab            | Standard. | Table of HMM scores at each level, suitable for visualization in R.         |
| LEVEL_result.tab           | Standard. | For the current prediction level, tab-delimited headers & predicted clades. |
| LEVEL_result.txt           | Standard. | For the current prediction level, A prettier output of the above.           |
| FASTA/                     | Standard. | Folder containing fasta files and newick trees.                             |
| FASTA/PROJ_predictions.fas | Standard. | Query sequence file with predictions added like: _{PRED:CLAD}               |
| FASTA/MOD_control.fasta    | Optional. | Alignment of predictions fasta file and guide sequences.                    |
| FASTA/MOD_control.nwk      | Optional. | Maximum likelihood tree of the above.                                       |
| FASTA/PROJ_reannotated.fas | Default.  | Query file with annotations replaced with predicted ones, ordered by clade. |
| FASTA/PROJ_ordered.fasta   | Optional. | Aligned version of the above, still ordered by clade.                       |
| FASTA/PROJ_tree.nwk        | Optional. | Maximum likelihood tree of the above.                                       |
| FASTA/PROJ_clade_CLAD.fas  | Standard. | The re-annotated file partitioned into separate clade files.                |
| c-*/                       | Standard. | Clade/lineage subfolder for the hierarchical predictions.                   |

*The project name is denoted "PROJ", the lineage or clade is called "CLAD", and the module of interest as “MOD”.*

## MODULES

LABEL modules are merely directories within the *LABEL\_RES/training\_data* folder and contain all associated pHMMs as well as SVM training data.  Extensions such *x-filter.txt* control against inappropriate data input.  The guide tree for positive control (if desired) is listed as *MOD\_downsample.fa* for MAFFT/MUSCLE alignment or in the *x-control* folder for faster pHMM alignment. See website for more information or use: `./LABEL -S`

## HARDWARE

We recommend a single multi-core machine with no fewer than 2 cores (8 or more threads work best) and at least 2 GB of RAM.  LABEL runtime is impacted by the number of cores available on a machine. Use with Mac OS X requires a 64 bit chipset.

## SOFTWARE PRE-REQUISITES

See "QUICK_INSTALL.txt".

## PACKAGED SOFTWARE

- SHOGUN version 1.0.0 or later (tested 1.1.0)
  - Purpose: executes the SVM decision phase.
  - License: GPL v3
- MUSCLE 3.8 or later (tested 3.8.11)
  - Purpose: optionally align output or control
  - License: Public Domain
- FastTreeMP 2.1.4 or later
  - Purpose: optionally build trees
  - License: GPL (any)
- SAM version 3.5 or later
  - Purpose: build HMM profiles, score sequences for evaluation
  - License: Academic/Government, not-for-profit, redistributed with permission
- BASH scripts
  - Purpose: assist installation, main pipeline for LABEL
  - License: owner, GPL
- Perl scripts
  - Purpose: data manipulation and formatting; calls SHOGUN for SVM use.
  - License: owner, GPL.
  
## INSTALLATION

1) Unzip the archive containing LABEL.
2) Move the file “LABEL” and the directory “*LABEL\_RES*” to a place in your PATH environment variable.  Otherwise, add the directory containing LABEL and *LABEL\_RES* to your PATH.
3) Restart your terminal emulator. Note: *LABEL\_RES* and LABEL must be in the same folder.
4) LABEL is now installed.  To test it, execute: LABEL test.fa test\_proj H9v2011
5) The file “*test.fa*” is given in the deployment archive. To access LABEL without using the PATH variable, cd to your extracted directory & substitute “./LABEL” for “LABEL” above.

## LICENSE

GPL version 3. This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see [*www.gnu.org/licenses/*](http://www.gnu.org/licenses/).

## DICLAIMER & LIMITATION OF LIABILITY

[SAM (align2model,hmmscore,modelfromalign)](http://compbio.soe.ucsc.edu/sam2src/) binaries may be used within LABEL for government and/or academic use only. Commercial use and redistribution for commercial use is excluded. Use of SAM implies this [license](http://compbio.soe.ucsc.edu/sam-lic/obj.0).

The materials embodied in this software are "as-is" and without warranty of any kind, express, implied or otherwise, including without limitation, any warranty of fitness for a particular purpose. In no event shall the Centers for Disease Control and Prevention (CDC) or the United States (U.S.) Government be liable to you or anyone else for any direct, special, incidental, indirect or consequential damages of any kind, or any damages whatsoever, including without limitation, loss of profit, loss of use, savings or revenue, or the claims of third parties, whether or not CDC or the U.S. Government has been advised of the possibility of such loss, however caused and on any theory of liability, arising out of or in connection with the possession, use or performance of this software.  In no event shall any other party who modifies and/or conveys the program as permitted according to GPL license [[*www.gnu.org/licenses/*](http://www.gnu.org/licenses/)], make CDC or the U.S. government liable for damages, including any general, special, incidental or consequential damages arising out of the use or inability to use the program, including but not limited to loss of data or data being rendered inaccurate or losses sustained by third parties or a failure of the program to operate with any other programs.  Any views, prepared by individuals as part of their official duties as United States government employees or as contractors of the United States government and expressed herein, do not necessarily represent the views of the United States government. Such individuals’ participation in any part of the associated work is not meant to serve as an official endorsement of the software. The CDC and the U.S. government shall not be held liable for damages resulting from any statements arising from use of or promotion of the software that may conflict with any official position of the United States government.
