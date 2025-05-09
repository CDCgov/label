# Third Party Software Manifest

- [GNU Parallel]
  - Artifacts: `parallel`
  - Requires: system Perl
  - Purpose: parallelization
  - License: [GPL v3]
- [SHOGUN] version 1.1.0 (2.1+ is not compatible)
  - Artifacts: `shogun` (cmdline_static)
  - Provided architectures: linux/x86_64, linux/aarch64, apple/x86_64 (arm64 via Rosetta2)
  - Purpose: executes the SVM decision phase.
  - License: [GPL v3]
- [SAM] version 3.5
  - Artifacts: `align2model`, `hmmscore`, `modelfromalign`
  - Provided architectures: linux/x86_64, linux/aarch64, apple/universal (arm64 + intel)
  - Purpose: build HMM profiles, score sequences for evaluation
  - License: [Custom][sam-license] academic/government, not-for-profit, redistributed [with permission]

[GNU Parallel]: https://www.gnu.org/software/parallel/
[with permission]: copyright_and_licenses/sam3.5/SAM%20Redistribution%20Special%20Permissions.pdf
[GPL v3]: https://www.gnu.org/licenses/gpl-3.0.txt
[SHOGUN]: https://github.com/shogun-toolbox/
[sam-license]: https://users.soe.ucsc.edu/~karplus/projects-compbio-html/sam-lic/obj.0
[SAM]: https://users.soe.ucsc.edu/~karplus/projects-compbio-html/sam2src/
