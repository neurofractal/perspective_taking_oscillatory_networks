## Time-Frequency Analysis

The sensor-level time-frequency analysis was computed using the following script:

```matlab
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is a script to run TF statistics at the sensor level.
%
% Data from the 4 experimental conditions is loaded into Matlab, and
% time-frequency representations calculated using a Hanning Taper.
%
% Participant's data is loaded into 4 grand-average arrays, and
% non-parametric statistics are calculated.
%
% Finally grand averages from the arrays for illustrative purposes.
%
% Written by Robert Seymour - December 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Prerequisites

  subject = sort({'DB','MP','GR','DS','EC','VS','AE','SY','GW',...
      'SW','DK','KT','KM','FL','AN','IG'});

grandavgA = [];  % variable to hold han_taper_LR_hard_comb
grandavgB = [];  % variable to hold han_taper_LR_easy_comb
grandavgC = [];  % variable to hold han_taper_VO_hard_comb
grandavgD = [];  % variable to hold han_taper_VO_easy_comb

for i=1:length(subject)
    %% CD to correct place and load in data (PC-relevant)
    cd(sprintf('D:\\pilot\\%s\\PS',subject{i}));
    load(sprintf('D:\\pilot\\%s\\PS\\data_LR_hard.mat',subject{i}))
    load(sprintf('D:\\pilot\\%s\\PS\\data_LR_easy.mat',subject{i}))
    load(sprintf('D:\\pilot\\%s\\PS\\data_VO_easy.mat',subject{i}))
    load(sprintf('D:\\pilot\\%s\\PS\\data_VO_hard.mat',subject{i}))

    %% Downsample
    cfg = [];
    cfg.resamplefs = 250;
    cfg.detrend = 'no';
    data_LR_hard_ds = ft_resampledata(cfg,data_LR_hard);
    data_LR_easy_ds = ft_resampledata(cfg,data_LR_easy);
    data_VO_hard_ds = ft_resampledata(cfg,data_VO_hard);
    data_VO_easy_ds = ft_resampledata(cfg,data_VO_easy);

    %% Redefine trial to make sure time-points are equivalent
    cfg = [];
    cfg.toilim = [-1.0 1.5];
    data_LH_hard_poststim = ft_redefinetrial(cfg, data_LR_hard_ds);
    data_LH_easy_poststim = ft_redefinetrial(cfg, data_LR_easy_ds);
    data_VO_hard_poststim = ft_redefinetrial(cfg, data_VO_hard_ds);
    data_VO_easy_poststim = ft_redefinetrial(cfg, data_VO_easy_ds);

    clear data_LH_easy_comb data_LH_hard_comb data_LH_easy_filtered
    clear data_LH_hard_filtered data_LR_easy_ds data_LR_hard_ds

    %% Time-Freq Analysis on the Gradiometers

    cfg = [];
    cfg.output       = 'pow';
    cfg.channel = {'MEGGRAD'};
    cfg.method       = 'mtmconvol';
    cfg.taper        = 'hanning';
    cfg.foi          = 0:1:30;                         % analysis 1 to 30 Hz in steps of 1 Hz
    cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.5;   % length of time window = 0.5 sec
    cfg.toi          = -1.0:0.05:1.0;                  % time window "slides" from 0 to 1 sec in steps of 0.05 sec (50 ms)
    disp(sprintf('Time of interest = %s',cfg.toi));
    cfg.keeptrials = 'no';
    han_taper_LR_hard = ft_freqanalysis(cfg, data_LH_hard_poststim);
    han_taper_LR_easy = ft_freqanalysis(cfg, data_LH_easy_poststim);
    han_taper_VO_hard = ft_freqanalysis(cfg, data_VO_hard_poststim);
    han_taper_VO_easy = ft_freqanalysis(cfg, data_VO_easy_poststim);

    % Since the data is of equal length we equalize the time axis of pre and post stimulus segments
    % as well as assuring that both frequency dimensions are also the same.
    han_taper_LR_easy.time = han_taper_LR_hard.time;
    han_taper_VO_hard.time = han_taper_LR_hard.time;
    han_taper_VO_easy.time = han_taper_LR_hard.time;

    % Add partiicpant label so we can keep track for later
    han_taper_LR_easy.subject = subject{i};
    han_taper_LR_hard.subject = subject{i};
    han_taper_VO_hard.subject = subject{i};
    han_taper_VO_easy.subject = subject{i};

    % Combine the gradiometers
    cfg = [];
    han_taper_LR_easy_comb = ft_combineplanar(cfg, han_taper_LR_easy);
    han_taper_LR_hard_comb = ft_combineplanar(cfg, han_taper_LR_hard);
    han_taper_VO_hard_comb = ft_combineplanar(cfg, han_taper_VO_hard);
    han_taper_VO_easy_comb = ft_combineplanar(cfg, han_taper_VO_easy);

    % Put into corresponding array
    grandavgA{i} = han_taper_LR_hard_comb;
    grandavgB{i} = han_taper_LR_easy_comb;
    grandavgC{i} = han_taper_VO_hard_comb;
    grandavgD{i} = han_taper_VO_easy_comb;

end


%% STATISTICAL ANALYSIS
cfg = [];
cfg.channel          = grandavgA{1, 1}.label;
cfg.latency          = [0 1];
cfg.frequency        = [1 30];
cfg.method           = 'montecarlo';
cfg.statistic        = 'ft_statfun_depsamplesT';
cfg.correctm         = 'cluster';
cfg.clusterstatistic = 'maxsum';
cfg.minnbchan        = 2;
cfg.tail             = 0;

cfg.numrandomization = 1000; %1000 randomisations

% Prepare neighbourhood relationships

cfg_neighb.template = 'neuromag306cmb.lay';
cfg_neighb.method    = 'distance';
cfg.feedback = 'yes';
cfg.neighbours       = ft_prepare_neighbours(cfg_neighb, grandavgA{1, 1});

% Prepare Design Matrix
nsubj=numel(grandavgA);
cfg.design(1,:) = [1:nsubj 1:nsubj];
cfg.design(2,:) = [ones(1,nsubj) ones(1,nsubj)*2];
cfg.uvar        = 1; % row of design matrix that contains unit variable (in this case: subjects)
cfg.ivar        = 2; % row of design matrix that contains independent variable (the conditions)

[stat_LR] = ft_freqstatistics(cfg, grandavgA{:}, grandavgB{:});
[stat_VO] = ft_freqstatistics(cfg, grandavgC{:}, grandavgD{:});

% Plot the results of this analysis
cfg = [];
cfg.layout       = 'neuromag306cmb.lay';
%cfg.maskparameter = 'mask';
cfg.parameter = 'stat';
ft_multiplotTFR(cfg, stat_LR)
figure;
ft_multiplotTFR(cfg, stat_VO)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% A prominent cluster of greater (3-6Hz) theta-band power was found in the
% LR-hard verus LR-easy condition. We therefore need to visualise this by
% computing the grandaverage and plotting using Fieldtrip's inbuilt
% plotting functions.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Grandaverage for plotting

% Path to plot_tfr_ps_theta.m script
addpath('D:\scripts\Perspective Taking\Perspective-Taking-MEG-Analysis');
subject = 'Group N=14';

% Compute Grand-averages
cfg = [];
[grandavg_LR_hard] = ft_freqgrandaverage(cfg, grandavgA{:});
[grandavg_LR_easy] = ft_freqgrandaverage(cfg, grandavgB{:});
[grandavg_VO_hard] = ft_freqgrandaverage(cfg, grandavgC{:});
[grandavg_VO_easy] = ft_freqgrandaverage(cfg, grandavgD{:});

% LR-hard>LR-easy ; VO-hard>VO-easy
cfg= [];
cfg.parameter = 'powspctrm';
cfg.operation = 'subtract';
[freqdiff_LR] = ft_math(cfg,grandavg_LR_hard,grandavg_LR_easy);
[freqdiff_VO] = ft_math(cfg,grandavg_VO_hard,grandavg_VO_easy);

% Plot Theta-band (3-6Hz) activity, 0-0.65s, using function plot_tfr_ps_theta
plot_tfr_ps_theta(freqdiff_LR,'pilot Group','LR_hard versus LR_easy')
plot_tfr_ps_theta(freqdiff_VO,'pilot Group','VO_hard versus VO_easy')

```
(Dependencies: MATLAB, Fieldtrip, plot_tfr_ps_theta.m)
