# Sample code for: Persistent activity during working memory maintenance predicts long-term memory formation in the human hippocampus

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![Generic badge](https://img.shields.io/badge/release-1.0.0-green.svg)](https://github.com/rutishauserlab/SBCAT-release-NWB/releases/tag/v1.0.0)
[![Generic badge](https://img.shields.io/badge/DOI-10.5281%2Fzenodo.10494534-orange.svg)](https://doi.org/10.5281/zenodo.10494534)

## Introduction

This repository contains the code that accompanies [Daume et. al. 2024b](https://www.biorxiv.org/content/10.1101/2024.07.15.603630v1) 'Persistent activity during working memory maintenance predicts long-term memory formation in the human hippocampus'. The purpose of the code in this repository is to provide examples of how to use the released data. This dataset is formatted in the [Neurodata Without Borders (NWB)](https://www.nwb.org/) format, which can easily be accessed from both MATLAB and Python as described [here](https://nwb-schema.readthedocs.io/en/latest/index.html). 

Abstract of the paper:
>Working Memory (WM) and Long-Term Memory (LTM) are often viewed as separate cognitive systems. Little is known about how these systems interact when forming memories. We recorded single neurons in the human medial temporal lobe while patients maintained novel items in WM and a subsequent recognition memory test for the same items. In the hippocampus but not the amygdala, the level of WM content-selective persist activity during WM maintenance was predictive of whether the item was later recognized with high confidence or forgotten. In contrast, visually evoked activity in the same cells was not predictive of LTM formation. During LTM retrieval, memory-selective neurons responded more strongly to familiar stimuli for which persistent activity was high while they were maintained in WM. Our study suggests that hippocampal persistent activity of the same cell supports both WM maintenance and LTM encoding, thereby revealing a common single-neuron component of these two memory systems. 




<p align="center">
  <img width="500" height="400" src="https://github.com/rutishauserlab/SBCAT_NO-release-NWB/blob/main/assets/Figure1.png">
</p>
<!--   <img width="400" height="500" src="https://placehold.co/400x500.png"> -->

## Installation (Code)

This repository can be downloaded by entering the following commands:

`cd $target_directory`

`git clone https://github.com/rutishauserlab/SBCAT-release-NWB.git`

## Installation (MatNWB)

Running the provided code and analyzing the dataset in MATLAB requires the download and initialization of MatNWB, a MATLAB interface for reading and writing NWB 2.x files. Instructions for how to [download and initialize MatNWB](https://github.com/NeurodataWithoutBorders/matnwb) have been listed on the project's public git repo. Further documentation for how to use MatNWB can be found [here](https://neurodatawithoutborders.github.io/matnwb/). MatNWB version [2.6.0.2](https://github.com/NeurodataWithoutBorders/matnwb/releases/tag/v2.6.0.2) was used for the curation and analysis of this dataset.

## Installation (Data)

The dataset is available in NWB format from the DANDI Archive under [DANDI:001187](https://dandiarchive.org/dandiset/001187). 
<!--This dataset is also available from the DABI Archive under [Placeholder](https://rb.gy/otj7q) -->

Dandi datasets are accessible through the Dandi command line interface (CLI). To install this Python client, use `pip install dandi` or `conda install -c conda-forge dandi`, depending on your Python environment setup. 

After installing the Dandi CLI, use `dandi download [insert dataset link]` to download the dataset. 

## File Validation (Python)

NWB Files can additionally be loaded and analyzed using the [PyNWB](https://github.com/NeurodataWithoutBorders/pynwb) python package. Further documentation can be found [here](https://pynwb.readthedocs.io/en/stable/). 

Validation of this dataset was performed using PyNWB (2.3.1) and PyNWB-dependent packages, such as nwbinspector (0.4.28) and dandi (0.55.1). The command lines used for each method are as follows:
* dandi: `dandi validate $target_directory`
* nwbinspector: `nwbinspector $target_directory`
* PyNWB: `$file_list = Get-ChildItem $target_directory -Filter *.nwb -Recurse | % { $_.FullName }; python -m pynwb.validate $file_list`

All validators returned no errors in data formatting & best-use practices across all uploaded files. 


## MATLAB Analysis

The main script in this repo, `NWB_SBCAT_SO_analysis_main.m`, is designed to analyze the released dataset and to reproduce select figures & metrics noted in Daume et. al. 2024b. It can calculate several metrics related to behavior (reaction time, accuracy) and single-unit (SU) activity during the task.

### Steps to Use the Script
* **Set Parameters:** The first section of the script sets important parameters. The `importRange` is the range of files for the dataset. For the current release, subject IDs have a range of `1:46`. The full range can also be specified by setting `importRange=[]`.

* **Initialization and Pathing:** The script then defines the directory paths for the code, the currently installed MatNWB package, and the dataset, and then adds them to the MATLAB path. If figures are generated, there is an additional option to add a custom save destination. Please ensure that the defined paths in the script are correct for your setup. This section also uses MatNWB's generateCore() function to initialize the NWB API if it has not been initialized already.

* **Import Datasets From Folder:** The script will then import datasets from the given folder using the `NWB_importFromFolder` function. Only files specified using `importRange` will be loaded into the workspace. 

* **Extracting Single Units:** Single unit information is extracted from the loaded NWB files for ease of indexing, using the `NWB_SB_extractUnits` function. If spike waveforms are not needed for analysis, the `load_all_waveforms` flag can be set to `0` to only extract the mean waveform. All future plots will use this mean waveform instead of a spike waveform pdf. 

* **Determine Category Cells:** This section determines category-selective neurons among all neurons. It is preceded by a parameters section, which allows for the control of various stages of the analysis and plotting process. For example, one can choose to plot figures for significant cells by setting `paramsSC.doPlot = 1` or filter units being used for analysis by specifying a minimum firing rate threshold `paramsSC.rateFilter`. To disable analysis of all cells entirely, set `paramsSC.calcSelective = 0`. 

* **Selectivity by Area:** This section calculates the proportion of category-selective cells across each area measured. It is intended to use `importRange = 1:46`.

* **Category neuron Example:** This section plots the example category-selective cell that can be found in Fig 2a of Daume et al. To decrease loading time, please set `importRange = 6`. 

* **GLM analysis:** This section computes the mixed-model GLM used for Fig. 3a in Daume et al. and prints/plots the results.

* **Determine Memory-selective Cells:** This section selects for MS neurons in both areas. Use the parameters section above to allow for the control of various stages of the analysis and plotting process. 

* **Memory-selective neuron example:** This section plots the example memory-selective cell that can be found in Fig 4a of Daume et al (2024b). To decrease loading time, please set `importRange = 25`. 

Please make sure to thoroughly read the comments in the code to understand the functionality of each part. If you encounter any problems, please report them as issues in the repository.


This repository has been tested in MATLAB versions 2019a & 2024a.

## Contributors
* [Jonathan Daume](mailto:Jonathan.Daume@cshs.org)
* [Sophia Cheng](mailto:sophia.cheng@cshs.org)
* [Michael Kyzar](mailto:kyzarnexus@gmail.com)
* [Ueli Rutishauser](mailto:Ueli.Rutishauser@cshs.org) (Principal Investigator)

>Citation: Daume et al. Persistent activity during working memory maintenance predicts long-term memory formation in the human hippocampus. Neuron (in press). [bioRxiv](https://www.biorxiv.org/content/10.1101/2024.07.15.603630v1)


## Funding

This work was supported by the National Institute of Health (U01NS117839 to U.R.), a Postdoctoral Fellowship by the German Academy of Sciences Leopoldina (to J.D.) and a Postdoctoral Award by the Center for Neural Science and Medicine at Cedars-Sinai (to J.D.).

## License 

"SBCAT-NO-release-NWB" Copyright (c) 2024, Rutishauser Lab. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

