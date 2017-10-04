# **Oscillatory Networks of Embodied Mental Alignment: a Perspective-Taking MEG study**

## **(Seymour, Wang, Rippon & Kessler., *in prep*)**

Mentally imagining another’s perspective is a high-level social process, reliant on manipulating internal representations of the self in an embodied manner. Recently [Wang et al.,](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5563337/) showed that theta-band (3-7Hz) brain oscillations within the right temporo-parietal junction (rTPJ) and brain regions coding for motor/body schema contribute to the process of perspective-taking. Using a task requiring participants to engage in embodied perspective-taking, we set out to unravel the extended functional brain network and its connections in detail. We found that increasing the angle of disparity between self and other perspective was accompanied by greater reaction times and increases in theta power within rTPJ, right lateral pre-frontal cortex (PFC) and right anterior cingulate cortex (ACC). Using nonparametric Granger-causality, we showed that during later stages of perspective-taking, the lateral PFC and ACC exert top-down influences over rTPJ, indicative of executive control processes required for managing conflicts between self and other perspectives. Finally, we quantified patterns of whole-brain phase coupling (imaginary coherence) in relation to rTPJ during high-level perspective taking. Results suggest that rTPJ increases its theta-band phase synchrony with brain regions involved in mentalizing and regions coding for motor/body schema; whilst decreasing its synchrony to visual regions. Implications for neurocognitive models are discussed, and it is proposed that rTPJ acts as a ‘hub’ to route bottom-up visual information to internal representations of the self during perspective-taking, co-ordinated by theta-band oscillations. The self is then projected onto the other’s perspective via embodied motor/body schema transformations, regulated by top-down cingulo-frontal activity.

This Github Page hosts a series of Matlab scripts describing the key behavioural and MEG data analysis steps in the above manuscript.

**(1) [Paradigm](http://robertseymour.me/perspective_taking_oscillatory_networks/paradigm)**

Adapted from [Kessler & Rutherford (2010)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3153818/)

**(2) [Behavioural Analysis](http://robertseymour.me/perspective_taking_oscillatory_networks/behavioural)**

ePrime log files were analysed using various scientific pyton packages

**(3) [Maxfilter](http://robertseymour.me/perspective_taking_oscillatory_networks/maxfilter)**

Software from [Elekta](http://imaging.mrc-cbu.cam.ac.uk/meg/Maxfilter) for cleaning MEG data

**(4) [Preprocessing](http://robertseymour.me/perspective_taking_oscillatory_networks/preprocessing)**

Performed in [Fieldtrip](http://www.fieldtriptoolbox.org/).

**(5) [Time-Frequency Analysis](http://robertseymour.me/perspective_taking_oscillatory_networks/tfr_analysis)**

Performed in [Fieldtrip](http://www.fieldtriptoolbox.org/). Statistical analysis via non-parametric cluster-based statistics.

**(6) [Source-Level Analysis](http://robertseymour.me/perspective_taking_oscillatory_networks/source_analysis)**

Performed in [Fieldtrip](http://www.fieldtriptoolbox.org/), using a DICS beamformer. Statistical analysis via non-parametric cluster-based statistics.

**(7) [Virtual Electrode & Low Frequency Power Computation](http://robertseymour.me/perspective_taking_oscillatory_networks/compute_VE_TPJ_ACC_PFC)**

Performed in [Fieldtrip](http://www.fieldtriptoolbox.org/), using an LCMV beamformer. Oscillatory power is computed using a Hanning Taper (following sensor-level analysis).

**(8) Granger-Causality Analysis (rTPJ, rACC, rPFC)** - coming soon

**(9) Imaginary Coherence (whole-brain from rTPJ)** - coming soon
