---
# **Perspective Taking MEG Analysis ABC**
## A repository of Matlab scripts and tutorials describing the key MEG data analysis steps in perspective taking task

**(Seymour, Gooding-Williams, Wang, Rippon & Kessler., *in prep*)**
---
## Paradigm

![Imgur](http://i.imgur.com/qC0zeor.jpg)

The paradigm was adopted from [Kessler and Rutherford](https://pdfs.semanticscholar.org/ed1e/740856d1c5d7e218e9ca3ab3fa056edcb9b4.pdf) (2010, Expt. 1). In all stimuli, an avatar was presented seated at a round table shown from one of four possible angular disparities (60°, 160° clockwise and anticlockwise). The stimuli were coloured photographs (resolution of 1024 × 768 pixels), taken from an angle of 65° above the plane of the avatar and table. The stimulus table contained four grey spheres (placed around an occluder). In each trial one of the spheres turned red indicating this sphere as the target. From the avatar's viewpoint, the target could be visible/occluded (perspective tracking task) or left/right (perspective taking task) and participants were asked to make a judgement according to the avatar's perspective by pressing the instructed key: the left key for “left” or “visible” targets and the right key for “right” or “occluded” targets. 

There were therefore 4 conditions:
>1. Left/right judgements where the avatar is 160&deg; from own perspective **(LR-hard)**
>2. Left-/right judgements where the avatar is 60&deg; from own perspective **(LR-easy)**
>3. Visible/occluded judgments where the avatar is 160&deg; from own perspective **(VO-hard)**
>4.  Visible/occluded judgments where the avatar is 60&deg; from own perspective **(VO-easy)**

## Behavioural Analysis
All behavioural data was first extracted from ePrime log files and concatenated into one CSV file. Participant reaction times were then analysed using the script below.



![Imgur](http://i.imgur.com/BITgNQ9.png)
This boxplot to shows participant’s mean reaction time (RT) in milliseconds for the 4 conditions of the perspective taking task. * = significantly different from all other conditions (p<.05). 

*Statistical analysis was performed using SPSS v21.*

As in Kessler & Rutherford (2010) the LR_hard task


## Maxfilter

## Preprocessing
