***This document is under governance review. When the review completes as appropriate per local and agency processes, the project team will be allowed to remove this notice. This material is draft.***

# LABEL, Lineage Assignment by Extended Learning

LABEL’s purpose is to quickly (relative to building an MSA and tree), automatically, and correctly assign clades or lineages to nucleotide sequences.  Automated lineage assignment has applications in surveillance, research, and high-throughput database annotation. Additional information is on the [LABEL website](https://wonder.cdc.gov/amd/flu/label/) or you can read the [manuscript].

## METHOD

Lineage Assignment By Extended Learning (LABEL) uses hidden Markov model (HMM) profiles of clade alignments--or groups of clades--to analyze query sequences and then classify them via machine learning techniques. The HMM scoring step is performed via [SAM]. Prediction is performed hierarchically--usually starting out at a more general level (e.g., a groups of clades) and going to a very specific terminal level (a particular clade). This roughly corresponds to the hierarchical structure of phylogenetic trees and the H5N1 nomenclature system. The prediction phase of LABEL is done via support vector machines (SVM) using the free SHOGUN Machine Learning Toolbox v1.1.0 (multi-class GMNP SVM with polynomial kernel of degree 20, <www.shogun-toolbox.org>).

### TRAINING

Training is performed using a combination of support scripts and by manually applied expert knowledge. Generally, a curated and annotated multiple sequence alignment is used along with the [createLABELlevel.sh](createLABELlevel.sh) script.

## USAGE

```bash
LABEL v0.7.0, updated 2025
Samuel S. Shepard (vfn4@cdc.gov), Centers for Disease Control & Prevention
Usage:
        LABEL [-E C_OPT] [-W WRK_PATH|-O OUT_PATH] [-TRD|-S] [-L LIN_PATH] <nts.fasta> <project> <Module:H5,H9,etc.>
                -T      Do TRAINING again instead of using classifier files.
                -E      SGE clustering option. Use 1 or 2 for SGE with array jobs, else local.
                -R      No RECURSIVE prediction. Limits scope, useful with -L option.
                -D      No DELETION of extra intermediary files.
                -S      Show available protein modules.
                -W      Web-server mode: requires ABSOLUTE path to WRITABLE working directory.
                -O      Output directory path, do not use with web mode.
Example: ./LABEL -C gisaid_H5N1.fa Bird_Flu H5
```

### DATA

- LABEL takes FASTA formatted nucleotide sequences.  The FASTA may be single or multi-line and may contain any number of sequences.  Extra sequences with redundant headers are removed (first-read, first kept)!  Commas and apostrophes are removed from headers while internal spaces are underlined.

- LABEL generates re-annotated FASTA sequences, scoring data, tab-delimited files, and miscellaneous text files.  LABEL's output is limited to text. LABEL's output is limited to a specified output directory (or to a default working directory within the package) and to the current working directory of the calling user.

### FILES GENERATED

| File                       | Type      | Description                                                                 |
| :------------------------- | :-------- | :-------------------------------------------------------------------------- |
| PROJ_final.tab             | Standard. | Tab-delimited headers & predicted clades.                                   |
| PROJ_final.txt             | Standard. | A prettier output of the above.                                             |
| LEVEL_trace.tab            | Standard. | Table of HMM scores at each level, suitable for visualization in R.         |
| LEVEL_result.tab           | Standard. | For the current prediction level, tab-delimited headers & predicted clades. |
| LEVEL_result.txt           | Standard. | For the current prediction level, A prettier output of the above.           |
| FASTA/                     | Standard. | Folder containing fasta files and newick trees.                             |
| FASTA/PROJ_predictions.fas | Standard. | Query sequence file with predictions added like: _{PRED:CLAD}               |
| FASTA/PROJ_reannotated.fas | Default.  | Query file with annotations replaced with predicted ones, ordered by clade. |
| FASTA/PROJ_clade_CLAD.fas  | Standard. | The re-annotated file partitioned into separate clade files.                |
| c-*/                       | Standard. | Clade/lineage subfolder for the hierarchical predictions.                   |

*The project name is denoted "PROJ", the lineage or clade is called "CLAD", and the module of interest as “MOD”.*

## MODULES

LABEL modules are merely directories within the *LABEL\_RES/training\_data* folder and contain all associated pHMMs as well as SVM training data. Extensions such as *x-filter.txt* control against inappropriate data input.

### Available Modules

Most of the these modules were train by Sam Shepard and/or Ujwal Bagal.

| Module                                                             | Description                                                                                                                                                     |
| ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **B_HAv2019**, B_HAv2017                                           | Influenza B hemagglutinin *clade* modules, trained in 2019 and 2017                                                                                             |
| B_NAv2016                                                          | Influenza B neuraminidase *clade* module, trained in 2016                                                                                                       |
| B_PB2v2016, B_PB1v2016, B_PAv2016, B_NPv2016, B_MPv2016, B_NSv2016 | Influenza B internal gene segment *lineage* modules, trained in 2016                                                                                            |
| †**H5v2023**                                                       | A provisional module for a **proposed** update to the H5 nomenclature, trained in 2023                                                                          |
| H5v2015, H5v2013, H5v2011                                          | Influenza A hemagglutinin modules for H5N1, for nomenclatures from [2015][H5-2015],  [c. 2013][H5-2013], & [c. 2011][H5-2011]                                   |
| †H7v2013                                                           | Influenza A hemagglutinin module for H7 subtype, trained in 2013                                                                                                |
| H9v2011                                                            | Influenza A hemagglutinin module for H9N2 described in the LABEL [manuscript]                                                                                   |
| **H1pdm09v2019**, H1pdm09v2018                                     | Influenza A H1N1pdm09 classification modules, trained in 2019 and 2018                                                                                          |
| **H3v2019**, H3v2016b, H3v2016a, H3v2016                           | Influenza A hemagglutinin modules for H3 subtype classification, trained in 2016 and 2019                                                                       |
| **irma-FLU**, irma-FLU-v2                                          | [IRMA] modules for influenza virus classification                                                                                                               |
| **irma-FLU-HA**, **irma-FLU-NA**, **irma-FLU-OG**, irma-FLU-OG-v2  | [IRMA] modules for influenza hemagglutinin, neuraminadase, and other influenza genes. Note: HA, NA and OG are part of IRMA's secondary two-stage LABEL modules. |
| irma-FLU-HE                                                        | [IRMA] module for hemagglutinin-esterase (flu C,D).                                                                                                             |

Modules may contain a `release.txt` file with addition information. For up-to-date module availability, use: `./LABEL -S`

† *Provisional or experimental*

[H5-2015]: http://onlinelibrary.wiley.com/doi/10.1111/irv.12324/full
[H5-2013]: http://onlinelibrary.wiley.com/doi/10.1111/irv.12230/full
[H5-2011]: http://onlinelibrary.wiley.com/doi/10.1111/j.1750-2659.2011.00298.x/full

## INSTALLATION & REQUIREMENTS

We recommend a single multi-core machine with no fewer than 2 cores (8 or more threads work best) and at least 2 GB of RAM.  LABEL runtime is impacted by the number of cores available on a machine. In addition software requirements include:

- Linux (RHEL8 or later GLIBC), MacOS 10.14 (intel) or MacOS 11 (arm64)
  - BASH version 3+
  - Standard utilities: sleep, cut, paste, jobs, zip, env, cat, cp, getopts.
- Perl version 5.16 or later
  - Standard includes: Getopt::Long, File::Basename

### Via Archive

Download the latest archive via our [releases page](https://github.com/CDCgov/label/releases). Use of `wget` or `curl` for downloads is *recommended for MacOS to preserve functionality*.

1) Unzip the archive containing LABEL.
2) Move the package to your desired location and add the folder to your `PATH`
   - Note: LABEL_RES and LABEL must be in the same folder.
3) LABEL is now installed.  To test it from the package folder, execute:

   ```bash
   ./LABEL LABEL_RES/training_data/H9v2011/H9v2011_downsample.fa test_project H9v2011
   ```

### Via Docker

Simply run:

```bash
docker run --rm -itv $(pwd):/data ghcr.io/cdcgov/label:latest LABEL # label args
```

## Third Party Software

We aggregate and provide [builds of 3rd party software](LABEL_RES/third_party/) for execution at runtime with LABEL. You may install or obtain your own copies and LABEL will detect them, but the user will be required to test for compatibility.

- [GNU Parallel]
  - Artifacts: parallel
  - Requires: system Perl
  - Purpose: parallelization
  - License: [GPL v3]
- [SHOGUN] version 1.1.0 (2.1+ is not compatible)
  - Artifacts: shogun (cmdline_static)
  - Provided architectures: linux/x86_64, linux/aarch64, apple/x86_64 (arm64 via Rosetta2)
  - Purpose: executes the SVM decision phase.
  - License: [GPL v3]
- [SAM] version 3.5
  - Artifacts: align2model, hmmscore, modelfromalign
  - Provided architectures: linux/x86_64, linux/aarch64, apple/universal (arm64 + intel)
  - Purpose: build HMM profiles, score sequences for evaluation
  - License: [Custom][sam-license] academic/government, not-for-profit, redistributed [with permission]

> [!WARNING]
> Note that [SAM] is redistributed with permission for LABEL but its terms exclude commerical use without a license. If you are a commercial entity, you might need to reach out to the authors to obtain their [custom][sam-license] license.

## DISCLAIMER & LIMITATION OF LIABILITY

## Notices

### Contact Info

For direct correspondence on the project, feel free to contact: [Samuel S. Shepard](mailto:sshepard@cdc.gov), Centers for Disease Control and Prevention or reach out to other [contributors](CONTRIBUTORS.md).

### Public Domain Standard Notice

This repository constitutes a work of the United States Government and is not subject to domestic copyright protection under 17 USC § 105. This repository is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).  All contributions to this repository will be released under the CC0 dedication.  By submitting a pull request you are agreeing to comply with this waiver of copyright interest.

### License Standard Notice

The repository utilizes code licensed under the terms of the Apache Software License and therefore is licensed under ASL v2 or later. This source code in this repository is free: you can redistribute it and/or modify it under the terms of the Apache Software License version 2, or (at your option) any later version. This source code in this repository is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the Apache Software License for more details. You should have received a copy of the Apache Software License along with this program. If not, see: <http://www.apache.org/licenses/LICENSE-2.0.html>. The source code forked from other open source projects will inherit its license.

### Privacy Standard Notice

This repository contains only non-sensitive, publicly available data and information. All material and community participation is covered by the [Disclaimer](https://github.com/CDCgov/template/blob/main/DISCLAIMER.md). For more information about CDC's privacy policy, please visit <http://www.cdc.gov/other/privacy.html>.

### Contributing Standard Notice

Anyone is encouraged to contribute to the repository by [forking](https://help.github.com/articles/fork-a-repo) and submitting a pull request. (If you are new to GitHub, you might start with a [basic tutorial](https://help.github.com/articles/set-up-git).) By contributing to this project, you grant a world-wide, royalty-free, perpetual, irrevocable, non-exclusive, transferable license to all users under the terms of the [Apache Software License v2](http://www.apache.org/licenses/LICENSE-2.0.html) or later.

All comments, messages, pull requests, and other submissions received through CDC including this GitHub page may be subject to applicable federal law, including but not limited to the Federal Records Act, and may be archived. Learn more at [http://www.cdc.gov/other/privacy.html](http://www.cdc.gov/other/privacy.html).

### Records Management Standard Notice

This repository is not a source of government records, but is a copy to increase collaboration and collaborative potential. All government records will be published through the [CDC web site](http://www.cdc.gov).

## Additional Standard Notices

Phe materials embodied in this software are "as-is" and without warranty of any kind, express, implied or otherwise, including without limitation, any warranty of fitness for a particular purpose. In no event shall the Centers for Disease Control and Prevention (CDC) or the United States (U.S.) Government be liable to you or anyone else for any direct, special, incidental, indirect or consequential damages of any kind, or any damages whatsoever, including without limitation, loss of profit, loss of use, savings or revenue, or the claims of third parties, whether or not CDC or the U.S. Government has been advised of the possibility of such loss, however caused and on any theory of liability, arising out of or in connection with the possession, use or performance of this software.  In no event shall any other party who modifies and/or conveys the program as permitted according to GPL license [[*www.gnu.org/licenses/*](http://www.gnu.org/licenses/)], make CDC or the U.S. government liable for damages, including any general, special, incidental or consequential damages arising out of the use or inability to use the program, including but not limited to loss of data or data being rendered inaccurate or losses sustained by third parties or a failure of the program to operate with any other programs.  Any views, prepared by individuals as part of their official duties as United States government employees or as contractors of the United States government and expressed herein, do not necessarily represent the views of the United States government. Such individuals’ participation in any part of the associated work is not meant to serve as an official endorsement of the software. The CDC and the U.S. government shall not be held liable for damages resulting from any statements arising from use of or promotion of the software that may conflict with any official position of the United States government.

[manuscript]: http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0086921
[GNU Parallel]: https://www.gnu.org/software/parallel/
[with permission]: LABEL_RES/third_party/copyright_and_licenses/sam3.5/SAM%20Redistribution%20Special%20Permissions.pdf
[GPL v3]: LABEL_RES/third_party/copyright_and_licenses/sam3.5/gpl-3.0.txt
[SHOGUN]: https://github.com/shogun-toolbox/
[sam-license]: https://users.soe.ucsc.edu/~karplus/projects-compbio-html/sam-lic/obj.0
[SAM]: https://users.soe.ucsc.edu/~karplus/projects-compbio-html/sam2src/
[IRMA]: https://bmcgenomics.biomedcentral.com/articles/10.1186/s12864-016-3030-6