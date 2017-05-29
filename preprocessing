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
