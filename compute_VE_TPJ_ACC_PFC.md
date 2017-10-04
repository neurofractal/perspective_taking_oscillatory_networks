## Virtual Electrode Computation from rTPJ, rACC and rPFC & Oscillatory Power

This script will compuet the low-frequency oscillatory power from 3 ROIs identified in the whole-brain analysis.

1. Right ACC (MNI co-ordinates: [12, 36, 28])
2. Right TPJ (MNI co-ordinates [40 -58 36])
3. Right lateral PFC (MNI co-ordinates: [52,32,16])

The script below computes the right TPJ VE for demonstration

```matlab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script computes a calculates a VE time-series from the right TPJ.
% Virtual electrode (VE) time-series are saved to disk.
% This is followed by TFR calculation from the VE data to estimate
% differences in oscillatory power between LR-hard and LR-easy conditions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Specify subject numbers and condition
subject = sort({'XX'}); condition = ({'LR_hard','LR_easy'});

for i = 1:length(subject)
    for cond = 1:length(condition)

        subject_within_loop = subject{i};
        condition_within_loop = condition{cond};

        virtualchannel_raw = get_VE_pers_data(subject_within_loop,condition_within_loop, [40 -58 36]);
        txt2save = ['virtualchannel_raw_' condition{cond} '_rTPJ'];
        save(txt2save,'virtualchannel_raw');
    end
end
```

The low frequency oscillatory power is then estimated for each condition using a Hanning taper. Oscillatory power within LR-hard versus LR-easy trials is compared and plotted.

```matlab
matrix_LR_easy_hanning = [];
matrix_LR_hard_hanning = [];

for i = 1:length(subject)
    cd(sprintf('D:\\pilot\\%s\\PS\\VE',subject{i}))
    load('virtualchannel_raw_LR_easy_rTPJ');
    load('virtualchannel_raw_LR_hard_rTPJ');

    %% Low Freqs
    cfg = [];
    cfg.method = 'mtmconvol';
    cfg.taper        = 'hanning';
    cfg.foi          = 0:1:30;                         % analysis 1 to 30 Hz in steps of 1 Hz
    cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.5;   % length of time window = 0.5 sec
    cfg.toi          = -0.75:0.05:1.3;                  % time window "slides" from -1.5 to 1.5 sec in steps of 0.05 sec (50 ms)
    disp(sprintf('Time of interest = %s',cfg.toi));
    hanning_easy = ft_freqanalysis(cfg, virtualchannel_raw_LR_easy_rTPJ); matrix_LR_easy_hanning{i} = hanning_easy;
    hanning_hard = ft_freqanalysis(cfg, virtualchannel_raw_LR_hard_rTPJ);matrix_LR_hard_hanning{i} = hanning_hard;
end

%% Concatenate TFRs across participants
cfg = [];
LR_easy_concat_hanning = ft_freqgrandaverage(matrix_LR_easy_hanning{1,:});
LR_hard_concat_hanning = ft_freqgrandaverage(matrix_LR_hard_hanning{1,:});

%% Compute Difference
grandavg_diff_hanning = [];

for i = 1:length(subject)
    cfg = [];
    cfg.operation = 'subtract';
    cfg.parameter = 'powspctrm';
    grandavg_diff_hanning{i}  = ft_math(cfg,matrix_LR_hard_hanning{i},matrix_LR_easy_hanning{i});
end

cfg = [];
hanning_diff = ft_freqgrandaverage(grandavg_diff_hanning{1,:});

%% Low Freqs - Produce TFR Plot for difference between LR_hard and LR_easy
cfg                 = [];
cfg.baselinetype    = 'absolute';
cfg.ylim            = [0 20];
cfg.baseline        = [-0.6 0];
cfg.xlim            = [-0.5 0.65]
cfg.zlim            = 'maxabs';
cfg.channel         = {'pos'};
figure; ft_singleplotTFR(cfg, hanning_diff);
colormap(jet);  set(gca,'FontSize',20); title('');
xlabel('Time (s)'); ylabel('Frequency (Hz)');
cd('C:\Users\seymourr\Dropbox\RS PhD Documents\Results\Perspective Taking')
print('rTPJ_VE_TFR_plot','-dpng','-r400')
```
