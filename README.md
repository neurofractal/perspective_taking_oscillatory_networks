# **Theta-Band Oscillations and The Role of The Right Temporo-Parietal Junction in Embodied Perspective-Taking - An MEG Study**

### **(Seymour, Gooding-Williams, Wang, Rippon & Kessler., *in prep*)**

### **A repository of Matlab scripts and tutorials describing the key behavioural and MEG data analysis steps**

## Paradigm
![Imgur](http://i.imgur.com/qC0zeor.jpg)

The paradigm was adopted from [Kessler and Rutherford](https://pdfs.semanticscholar.org/ed1e/740856d1c5d7e218e9ca3ab3fa056edcb9b4.pdf) (2010, Expt. 1). In all stimuli, an avatar was presented seated at a round table shown from one of four possible angular disparities (60°, 160° clockwise and anticlockwise). The stimuli were coloured photographs (resolution of 1024 × 768 pixels), taken from an angle of 65° above the plane of the avatar and table. The stimulus table contained four grey spheres (placed around an occluder). In each trial one of the spheres turned red indicating this sphere as the target. From the avatar's viewpoint, the target could be visible/occluded (perspective tracking task) or left/right (perspective taking task) and participants were asked to make a judgement according to the avatar's perspective by pressing the instructed key: the left key for “left” or “visible” targets and the right key for “right” or “occluded” targets. 

There were therefore 4 conditions:
>1. Left/right judgements where the avatar is 160&deg; from own perspective **(LR-hard)**
>2. Left-/right judgements where the avatar is 60&deg; from own perspective **(LR-easy)**
>3. Visible/occluded judgments where the avatar is 160&deg; from own perspective **(VO-hard)**
>4.  Visible/occluded judgments where the avatar is 60&deg; from own perspective **(VO-easy)**

## Behavioural Analysis

All behavioural data was first extracted from ePrime log files and concatenated into one CSV file. Participant reaction times were then extracted and analysed using the following Python script below.
```python
# -*- coding: utf-8 -*-
"""
@author: Robert Seymour

Script to analyse the behavioural output of the perspective taking task. 

It requires a CSV file in which all eprime data has been merged and pasted 
into the same array. 

"""

## Import required variables
import csv
import numpy as np
from matplotlib import pyplot as plt; 

## Location of CSV files
csvfile = ''

output = [];

## Deliniarate the csv file
with open(csvfile) as f:
    for line in f:
        cells = line.split( "," )
        output.append( ( cells[ : ]) )
    
participant_list = sorted(['2','4','7','9','10','11','13','14','15','17','19','18','20','21','22','25','8','24'])

## Function to Extract RT info from the CSV file
def extract_RT(participant_list,output,perspective_taking_level, angle):
    
    # INPUTS:
    # - participant_list = list of particpants
    # output = CSV file
    # perspective_taking_level = 1 or 2
    # angle = 60 or 160

    # OUTPUTS:
    # RT_list    
    
    RT_list = [[] for x in xrange(len(participant_list))]
        # For every participant...          
    for p in range(0,len((participant_list)),1):
        # Iterate through list looking for matching condition
        for n in range(1,(len(output)),1):
            if output[n][1] == participant_list[p] and output[n][32] == '1' \
                     and output[n][23] == perspective_taking_level and \
                               output[n][30] == angle:
                # Put RT into the RT array
                RT_list[p].append(float(output[n][36]))
        
        # Remove RT cases 2SD from the mean
        twostd_val = np.mean(RT_list[p])+2*(np.std(RT_list[p]))       
        RT_list[p] = [x for x in RT_list[p] if x<twostd_val]
    return RT_list

## Extract RT
RT_LR_hard = extract_RT(participant_list,output,'vpt2proc', '160')
RT_LR_easy = extract_RT(participant_list,output,'vpt2proc', '60')
RT_VO_hard = extract_RT(participant_list,output,'vpt1proc', '160')
RT_VO_easy = extract_RT(participant_list,output,'vpt2proc', '60')

## Function to make a boxplot for participantxRT data for each condition
def make_boxplot_1(RT_scores,n,participant_list,title):
    plt.figure(n)
    plt.boxplot(RT_scores,labels = participant_list,showfliers=False)
    plt.title(title)
    plt.xlabel('Partipant Code')
    plt.ylabel('Reaction Time (msec)')
    plt.show()
    
make_boxplot_1(RT_LR_hard,1,participant_list,'LR_hard')
make_boxplot_1(RT_LR_easy,2,participant_list,'LR_easy')
make_boxplot_1(RT_VO_hard,3,participant_list,'VO_hard')
make_boxplot_1(RT_VO_easy,4,participant_list,'VO_easy')

## Get medians from each participant
def get_group_data(participant_list,RT_scores):
    data_mean = []
    for nnn in range(0,len((participant_list)),1):
        data_mean.append(np.median(RT_scores[nnn]))
    return data_mean

data_LR_hard_median = get_group_data(participant_list,RT_LR_hard)
data_LR_easy_median = get_group_data(participant_list,RT_LR_easy)
data_VO_hard_median = get_group_data(participant_list,RT_VO_hard)
data_VO_easy_median = get_group_data(participant_list,RT_VO_easy)

data = [data_LR_hard_median,data_LR_easy_median, data_VO_hard_median, data_VO_easy_median]

## Show Bar-Graph
labels = ('LR_hard','LR_easy','VO_hard','VO_easy')
group_means = [np.mean(data[0]),np.mean(data[1]),np.mean(data[2]),np.mean(data[3])]
y_pos = np.arange(len(group_means))
plt.figure(5)
plt.bar(y_pos, group_means, align='center', alpha=0.4)
plt.xticks(y_pos, labels)
plt.ylabel('RT (ms)')
plt.title('Group Mean RTs')
 
plt.show()

## Beeswarm Plot
   
plt.rcParams["font.family"] = "arial"
            
from beeswarm import *               

beeswarm([[],data_LR_hard_median,data_LR_easy_median,data_VO_hard_median,data_VO_easy_median], method="swarm", labels=["","data_LR_hard", "data_LR_easy","data_VO_hard","data_VO_easy"], col=["red","red","red","red","red"])
plt.ylabel('RT (msec)',fontsize = 15)
plt.tick_params(axis='both', which='major', labelsize=15)
bp = plt.boxplot(data,labels = ['LR-hard','LR-easy','VO-hard','VO-easy'],showfliers=False) 

## change outline color, fill color and linewidth of the boxes
for box in bp['boxes']:
    # change outline color
    box.set( color='#000000', linewidth=1)
    # change fill color
    #box.set( facecolor = '#1b9e77' )

## change color and linewidth of the whiskers
for whisker in bp['whiskers']:
    whisker.set(color='#000000', linewidth=1)

## change color and linewidth of the caps
for cap in bp['caps']:
    cap.set(color='#2d3582', linewidth=1)

## change color and linewidth of the medians
for median in bp['medians']:
    median.set(color='#0000FF', linewidth=3)

## change the style of fliers and their fill
for flier in bp['fliers']:
    flier.set(marker='o', color='#000000', alpha=0.5)  

plt.savefig('all_conditions_boxplot_with_data.png',dpi=600)
```        
(Dependencies: [Spyder](https://github.com/spyder-ide), [Beeswarm](https://github.com/mgymrek/pybeeswarm))


![Imgur](http://i.imgur.com/basFipk.png)

*\* = significantly different from all other conditions (p<.05)*

This boxplot to shows participant’s mean reaction time (RT) in milliseconds for the 4 conditions of the perspective taking task. Statistical analysis was performed using SPSS v21.

As in Kessler & Rutherford (2010) performance in the LR-hard condition was accompanied by significantly longer reaction time (RT) compared with all other experimental conditions.

## MEG Data

Each subject's MEG data was saved in 3 separate blocks as follows:

>rs_asd_subjectname_pers_blocknumber

## Maxfilter

All MEG data were pre-processed using Maxfilter (temporal signal space separation, .96 correlation), which supresses external sources of noise from outside the head ([Taulu & Simola, 2006](http://iopscience.iop.org/article/10.1088/0031-9155/51/7/008/meta)). To compensate for head movement between runs, data from runs 2 and 3 were transformed to participant’s head position at the start of the first block using the –trans option of Maxfilter.

This was performed using the following Matlab script.


```matlab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Function to Maxfilter all rs_asd_XXX_persX.fif files in a directory 
%
% Use as maxfilter_all_RS('path_to_directory')
% Make sure there are no Maxfiltered datasets in your directory alread.
%
% This script will to the following things (and may take a while!):
%
% 1. Applies tSSS .96 correlation to ...pers1.fif data
% 2. Applies tSSS .96 correlation and -trans to ...pers2/3.fif data
% 3. Visualises PS movement using a script from Cambridge MRC Unit
%
% These are currently the best Maxfilter parameters for the data (although
% this could change!)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function maxfilter_all_RS(directory)


%% Specify current directory
cd(directory)

%% Put persX.fif into array but ignore any fif files already undergone tSSS
dir_list = dir('**pers*.fif');
pers_files = [];
p = 1;
for i=1:length(dir_list)
    matches = strfind(dir_list(i).name,'tsss');
    if isempty(matches) == 1
        pers_files{p} = dir_list(i).name;
        p = p+1;
    end
end

disp(pers_files)

%% Apply tSSS + movt estimation to data from the first run
% Here I'm applying ctc, cal, tSSS 30s buffer, corr limit 0.96, saving head
% pos output in a log file, and subtracting HPI coil noise

for i=1
    ddd = (sprintf('maxfilter -f %s -bad 0111 2542 0532 0613 -ctc /neuro/databases/ctc/ct_sparse.fif -cal /neuro/databases/sss/sss_cal.dat -v -force -st 30 -corr 0.96 -headpos -hp headpos_output_%s.log -hpisubt amp | tee output_log_%s.log',[cd '/' pers_files{1}],pers_files{1},pers_files{1}))
    disp(sprintf('About to process FIRST PERSPECTIVE TAKING DATSET %s using Maxfilter tSSS .96 correlation',pers_files{1}))
    system(ddd)
    clear ddd
    system(ls)
end

%% Here I am applying tSSS to data from runs 2 & 3, but also transforming data to the starting position of run 1

for i= [2 3]
    ddd = (sprintf('maxfilter -f %s -bad 0111 2542 0532 0613 -ctc /neuro/databases/ctc/ct_sparse.fif -cal /neuro/databases/sss/sss_cal.dat -v -force -st 30 -corr 0.96 -trans %s -hpisubt amp',[cd '/' pers_files{i}],[cd '/' pers_files{1}]))
    disp(sprintf('About to transform PERSPECTIVE TAKING DATSET %s using Maxfilter & tSSS .96 correlation',pers_files{i}))
    system(ddd)
    clear ddd
    system(ls)
end

%% Log head movements for runs 2 & 3

for i= [2 3]
    ddd = (sprintf('maxfilter -f %s -bad 0111 2542 0532 0613 -force -v -headpos -hp headpos_output_%s.log | tee output_log_%s.log',[cd '/' pers_files{i}],pers_files{i},pers_files{i}))
    disp(sprintf('About to transform PERSPECTIVE TAKING DATSET %s using Maxfilter & tSSS .96 correlation',pers_files{i}))
    system(ddd)
    clear ddd
    system(ls)
end

%% Visualising Movement

movecomppers_files = {};
for i =1:length(pers_files)
    movecomppers_files{i} = sprintf('output_log_%s.log', pers_files{i})
end
nr_pers_files = length(movecomppers_files);

for ff = 1:nr_pers_files
    addpath('/studies/201601-108/scripts/maxfilter'); %only relevant for my computer
    fprintf(1, 'Processing %s\n', movecomppers_files{ff});
    [mv_fig, linet, linee, lineg, linev, liner, lined] = check_movecomp(movecomppers_files{ff}); % read info from log-file
    [a,b,c] = fileparts(movecomppers_files{ff} );
    tittxt = [b]; % just one way to keep the figure title short
    figure( mv_fig );
    % check_movecomp only creates the figure, but without the title, so you can do this separately
    ht = title(tittxt); set(ht, 'interpreter', 'none'); % add title to figure
    saveas(gcf,sprintf('%s_movement.png',b))
end


end
```
(Dependencies: MATLAB, Maxfilter 2.2, [check_movecomp.m](http://imaging.mrc-cbu.cam.ac.uk/meg/maxdiagnost))

## Preprocessing

All subsequent analysis was performed in Matlab 2014b using the open-source Fieldtrip toolbox (Oostenveld, Fries, Maris, & Schoffelen, 2010), and customised Matlab scripts. 

The following preprocessing steps were applied to all datasets:

1. Load in data to Fieldtrip
2. Apply appropriate filters
3. Epoch based on specific trigger
4. Artefact Rejection
5. Save and repeat for data from runs 1-3

6. Concatenate data
7. Run FASTICA algorithm, detect ECG & EOG artefacts, remove from data
8. Save data_clean.mat

Script: preprocessing_elektra_FT_perspective_taking_pilot.m

```matlab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is a Matlab script to analyse Elekta data in Fieldtrip
% This runs through the common preprocessing, visualisation
% and artefact rejection steps. Any issues with this email me at
% seymourr@aston.ac.uk.
%
% Data are first saved from each specific run (#1-3) pre-ICA. These data
% are saved as data_clean_noICA + number of run
%
% After this data from all three runs are loaded, concatenated and ICA
% performed to clean any EOG/ECG remaining. This is saved as the
% variable data_clean
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Specfiy Subject ID & Condition
subject = 'XX';
PS_run = '1'; % 1, 2 or 3

%% Prerequisites
% Set your current directory
cd(sprintf('D:\\pilot\\%s\\PS\\',subject)) % only relevant for my computer

% Specify location of the datafile (change to trans in 2 & 3)
if strcmp(PS_run,'1');
    rawfile = sprintf('D:\\pilot\\raw_PS_data\\rs_asd_%s_pers%s_quat_tsss.fif',num2str(subject),PS_run);

else
    rawfile = sprintf('D:\\pilot\\raw_PS_data\\rs_asd_%s_pers%s_trans_tsss.fif',num2str(subject),PS_run);
end

% Perform ft_qualitycheck
cfg = [];
cfg.dataset = rawfile;
ft_qualitycheck(cfg)

% Creates log file
diary(sprintf('log_run%s_preICA.out',PS_run));

% Display General Script Info and Current Time & Date
t = [datetime('now')];
disp(sprintf('Preprocessing the Perspective Taking Data for Subject %s Run Number %s',subject,PS_run))
disp(t);

%% Epoching & Filtering
% Epoch the whole dataset into one continous dataset and apply
% the appropriate filters
cfg = [];
cfg.headerfile = rawfile;
cfg.datafile = rawfile;
cfg.channel = 'MEG';
cfg.trialdef.triallength = Inf;
cfg.trialdef.ntrials = 1;
cfg = ft_definetrial(cfg)

cfg.continuous = 'yes';
cfg.bpfilter = 'yes';
cfg.bpfreq = [0.5 250];
cfg.channel = 'MEG';
cfg.dftfilter = 'yes';
cfg.dftfreq = [50];
alldata = ft_preprocessing(cfg);

% Deal with 50Hz line noise
cfg = [];
cfg.bsfilter = 'yes';
cfg.bsfreq = [49.5 50.5];
alldata = ft_preprocessing(cfg,alldata);

% Deal with 100Hz line noise
cfg = [];
cfg.bsfilter = 'yes';
cfg.bsfreq = [99.5 100.5];
alldata = ft_preprocessing(cfg,alldata);

% Epoch your filtered data based on a specific trigger(s)
cfg = [];
cfg.headerfile = rawfile;
cfg.datafile = rawfile;
cfg.channel = 'MEG';
cfg.trialdef.eventtype = 'Trigger';
cfg.trialdef.eventvalue = [5:1:12]; % here we use values 5-12
cfg.trialdef.prestim = 1.0;        % pre-stimulus interval = 1000ms
cfg.trialdef.poststim = 1.5;        % post-stimulus interval = 1500ms
cfg = ft_definetrial(cfg);
data = ft_redefinetrial(cfg,alldata); %redefines the filtered data
clear alldata

data.rawtrialnumber = [1:1:128];

% Interactive bit of script so that the user can specify trials they wish
% to remove due to an incorrect responses & resonses greater than 2SD from the mean.
% Refer to participant EDAT files for this information.
disp('Enter trial number(s) to be removed in the form [1 2 3]')
trial2remove = input('Which trials would you like to remove?\n');
trial_list = [1:1:128];
trial_list(trial2remove) = [];

cfg = [];
cfg.trials = trial_list;
data = ft_redefinetrial(cfg,data);
clear trial_list trial2remove

% Detrend and demean each trial
cfg = [];
cfg.demean = 'yes';
cfg.detrend = 'yes';
data = ft_preprocessing(cfg,data)

%% Reject Trials
% Display visual trial summary to reject deviant trials.
% You need to load the mag + grad separately due to different scales

cfg = [];
cfg.method = 'summary';
cfg.keepchannel = 'yes';
cfg.channel = 'MEGMAG';
clean1 = ft_rejectvisual(cfg, data);
% Now load this
cfg.channel = 'MEGGRAD';
clean2 = ft_rejectvisual(cfg, clean1);
data = clean2; clear clean1 clean2
close all

%% Display Data
% Displaying the (raw) preprocessed MEG data

diary off
cfg = [];
cfg.channel = 'MEGGRAD';
cfg.viewmode = 'vertical';
ft_databrowser(cfg,data)
cfg.channel = 'MEGMAG';
ft_databrowser(cfg,data)
diary on

% Load the summary again so you can manually remove any deviant trials
cfg = [];
cfg.method = 'summary';
cfg.keepchannel = 'yes';
cfg.channel = 'MEG';
data = ft_rejectvisual(cfg, data);

% Save data - this could be done more smoothly?
data_clean_noICA = data
assignin('base',['data_clean_noICA' (PS_run)],data_clean_noICA)
disp('Saving data_clean_noICA...');
save(['data_clean_noICA' (PS_run)],['data_clean_noICA' (PS_run)],'-v7.3')
clear data_clean_noICA data
clear((['data_clean_noICA' (PS_run)]))
close all; diary off


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stop here and re-run for all runs (1-3)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% !!! ICA !!!

% Creates log file
diary(sprintf('log_%s_ICA.out',subject));

% Current Time & Date
t = [datetime('now')];
disp(sprintf('Performing ICA for Subject %s',subject))
disp(t);

% Load the pre-ICA data from runs 1-3
load('data_clean_noICA1'); ICA1 = ones(length(data_clean_noICA1.trial),1);
load('data_clean_noICA2'); ICA2 = ones(length(data_clean_noICA2.trial),1)*2;
load('data_clean_noICA3'); ICA3 = ones(length(data_clean_noICA3.trial),1)*3;

cfg = [];
data = ft_appenddata(cfg,data_clean_noICA1, data_clean_noICA2, data_clean_noICA3);
% Replace grad, header and label - these dissapear for some reason...
data.grad = data_clean_noICA1.grad; data.label = data_clean_noICA1.label; 
data.hdr = data_clean_noICA1.hdr;
% Add field to keep track of which run each trial came from
data.run_number = vertcat(ICA1,ICA2,ICA3);
clear data_clean_noICA1 data_clean_noICA2 data_clean_noICA3 ICA1 ICA2 ICA3

% Downsample
data_orig = data; %save the original CLEAN data for later use
cfg = [];
cfg.resamplefs = 150; %downsample frequency
cfg.detrend = 'no';
disp('Downsampling data');
data = ft_resampledata(cfg, data);
diary off

% Run ICA
disp('About to run ICA using the FASTICA method')
cfg            = [];
cfg.numcomponent = 64;
cfg.method     = 'fastica';
comp           = ft_componentanalysis(cfg, data);

save('comp.mat','comp','-v7.3')

% Display Components - change layout as needed
cfg = [];
cfg.viewmode = 'component';
cfg.layout = 'neuromag306mag.lay';
ft_databrowser(cfg, comp)
cfg.layout = 'neuromag306planar.lay';
ft_databrowser(cfg, comp)

%% Remove components from original data
%% Decompose the original data as it was prior to downsampling
diary on;
disp('Decomposing the original data as it was prior to downsampling...');
cfg           = [];
cfg.unmixing  = comp.unmixing;
cfg.topolabel = comp.topolabel;
comp_orig     = ft_componentanalysis(cfg, data_orig);

%% the original data can now be reconstructed, excluding specified components
% This asks the user to specify the components to be removed
disp('Enter components in the form [1 2 3]')
comp2remove = input('Which components would you like to remove?\n');
cfg           = [];
cfg.component = [comp2remove]; %these are the components to be removed
data_clean    = ft_rejectcomponent(cfg, comp_orig,data_orig);

%% Save the clean data
disp('Saving data_clean...');
save('data_clean','data_clean','-v7.3');
diary off
close all

%% Display clean data
cfg = [];
cfg.channel = 'MEGGRAD';
cfg.viewmode = 'vertical';
ft_databrowser(cfg,data_clean)
cfg.channel = 'MEGMAG';
ft_databrowser(cfg,data_clean)
```
(Dependencies: MATLAB, [Fieldtrip Toolbox](http://www.fieldtriptoolbox.org/))

Finally, the data were separated into the four experimental conditions using the code below, and saved to disk.

```matlab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Splitting the concatenated data into the 4x specific trial types:

% 1) Left/Right Easy (60deg/300deg) --> data_LR_easy
% 2) Left/Right Hard (160deg/200deg) --> data_LR_hard
% 3) Visual/Occluded Easy (60deg/300deg) --> data_VO_easy
% 4) Visual/Occluded Hard (160deg/200deg) data_VO_hard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% data_LR_easy

data_LR_easy_trials = vertcat(find(data_clean.trialinfo == 5),...
    find(data_clean.trialinfo == 8));

cfg = [];
cfg.trials = data_LR_easy_trials;
data_LR_easy = ft_redefinetrial(cfg,data_clean); %redefines the data
save('data_LR_easy','data_LR_easy','-v7.3')

%% data_LR_hard

data_LR_hard_trials = vertcat(find(data_clean.trialinfo == 6),...
    find(data_clean.trialinfo == 7));

cfg = [];
cfg.trials = data_LR_hard_trials;
data_LR_hard = ft_redefinetrial(cfg,data_clean); %redefines the data
save('data_LR_hard','data_LR_hard','-v7.3')

%% data_VO_easy

data_VO_easy_trials = vertcat(find(data_clean.trialinfo == 9),...
    find(data_clean.trialinfo == 12));

cfg = [];
cfg.trials = data_VO_easy_trials;
data_VO_easy = ft_redefinetrial(cfg,data_clean); %redefines the data
save('data_VO_easy','data_VO_easy','-v7.3')

%% data_VO_hard

data_VO_hard_trials = vertcat(find(data_clean.trialinfo == 10),...
    find(data_clean.trialinfo == 11));

cfg = [];
cfg.trials = data_VO_hard_trials;
data_VO_hard = ft_redefinetrial(cfg,data_clean); %redefines the data
save('data_VO_hard','data_VO_hard','-v7.3')

```
## Time-Frequency Analysis

Script [here](http://robertseymour.me/perspective-taking-MEG-analysis-ABC/tfr_perspective_taking)
