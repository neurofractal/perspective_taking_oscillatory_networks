## Computation of Whole-Brain Imaginary Coherence Using a Right TPJ Seed

This script computes imaginary coherence in source-space, using a right TPJ seed as reference. Coherence is computed from LR-hard and LR-easy trials, and compared using cluster-based nonparametric statistics. Full details in the manuscript text and code below.

```matlab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This scripts performs coherence analysis in the theta band, using PCC
% as the source localisation technique and imaginary coherence as the
% connectivity metric.
%
% Data is from the perspective taking task - 'LR_hard','LR_easy' conditions
% in the 0-0.65s period. Each condition is baseline corrected – ie. the
% coherence maps from the active period are subtracted from the baseline
% period coherence maps. The LR_hard > LR_easy contrast is then applied.
%
% Written by Robert Seymour (ABC)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Specify subject initials
subject = sort({'XX'});

chans_included = {'MEGGRAD', '-MEG0322', '-MEG2542','-MEG0111','-MEG0532'}; %Channels to use
condition = {'LR_hard','LR_easy'};%,'VO_easy','VO_hard'};

%% Loop for all subjects & all conditions
for i=1:length(subject)
    %% Create leadfields in subject's brain warped to MNI space
    % Loads variables needed for source analysis
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\mri_realigned.mat',subject{i}))
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\sens.mat',subject{i}))
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\seg.mat',subject{i}))

    % Load template sourcemodel
    load('D:\fieldtrip-20160208\template\sourcemodel\standard_sourcemodel3d8mm.mat');
    template_grid = sourcemodel;
    template_grid = ft_convert_units(template_grid,'mm');
    clear sourcemodel;

    % construct the volume conductor model (i.e. head model) for each
    % subject
    cfg        = [];
    cfg.method = 'singleshell';
    headmodel  = ft_prepare_headmodel(cfg, seg);

    % create the subject specific grid, using the template grid that
    % has just been created (i.e. warp to MNI space)
    cfg                = [];
    cfg.grid.warpmni   = 'yes';
    cfg.grid.template  = template_grid;
    cfg.grid.nonlinear = 'yes'; % use non-linear normalization
    cfg.mri            = mri_realigned;
    cfg.grid.unit      ='mm';
    grid               = ft_prepare_sourcemodel(cfg);

    % make a figure of the single subject headmodel, and grid positions
    %         figure; hold on; %Fig1
    %         ft_plot_vol(headmodel, 'edgecolor', 'none', 'facesourceloc', 0.4);
    %         ft_plot_mesh(grid.pos(grid.inside,:));
    %         ft_plot_sens(sens, 'style', 'r*')
    %         drawnow;

    % create leadfield
    cfg = [];
    cfg.channel = chans_included;
    cfg.grid = grid;
    cfg.vol = headmodel;
    cfg.grad = sens;
    cfg.normalize = 'yes'; % Do we need to normalise?
    lf = ft_prepare_leadfield(cfg)

    % For each condition...
    for con = 1:length(condition)
        %% Load the required variables you computed earlier
        % Loads correct data from specified condition
        load(sprintf('D:\\pilot\\%s\\PS\\data_%s.mat',subject{i},condition{con}))

        %% CD to correct place
        cd(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\',subject{i}))

        %% Load in data variable of interest
        data_clean = eval(sprintf('data_%s',condition{con}));

        %% Reduce the data to X number of components (stabilises covar matrix)
        covar = zeros(numel(data_clean.label));
        for itrial = 1:numel(data_clean.trial)
            currtrial = data_clean.trial{itrial};
            covar = covar + currtrial*currtrial.';
        end
        [V, D] = eig(covar);
        D = sort(diag(D),'descend');
        D = D ./ sum(D);
        Dcum = cumsum(D);
        numcomponent = find(Dcum>.99,1,'first') +1; % number of components accounting for 99% of variance in covar matrix

        disp(sprintf('\n Reducing the data to %d components \n',numcomponent));

        cfg = [];
        cfg.method = 'pca';
        cfg.updatesens = 'yes';
        cfg.channel = 'MEG';
        comp = ft_componentanalysis(cfg, data_clean);

        cfg = [];
        cfg.updatesens = 'yes';
        cfg.component = comp.label(numcomponent:end);
        data_fix = ft_rejectcomponent(cfg, comp);

        %% Downsample to 250Hz
        cfg = [];
        cfg.resamplefs = 250;
        cfg.detrend = 'no';
        data_clean_200 = ft_resampledata(cfg,data_fix);

        %% Cut out windows of interest
        cfg = [];
        cfg.toilim = [-0.65 0];
        dataPre = ft_redefinetrial(cfg, data_clean_200);

        cfg.toilim = [0 0.65];
        dataPost = ft_redefinetrial(cfg, data_clean_200);

        cfg.toilim = [-0.65 0.65];
        dataAll = ft_redefinetrial(cfg, data_clean_200);

        %% Do ya Freq Analysis
        % Here I am getting the fourier output of dataAll,Pre,Post
        cfg = [];
        cfg.grad = sens;
        cfg.keeptrials = 'yes';
        cfg.taper = 'hanning';
        cfg.method    = 'mtmfft';
        cfg.output    = 'fourier';
        cfg.tapsmofrq = 2; % Frequency Smoothing = 2Hz (EITHER SIDE)
        cfg.foi    = 5; % Frequency of Interest = 5
        freqAll = ft_freqanalysis(cfg, dataAll);
        freqPre = ft_freqanalysis(cfg, dataPre);
        freqPost = ft_freqanalysis(cfg, dataPost);

        %% Do ya beamforming

        addpath('D:\fieldtrip-bug3029') % FT has a bug for PCC - this solves it

        % Get filter for all your data
        cfg=[];
        cfg.frequency = 5;
        cfg.keeptrials = 'yes';
        cfg.grad = sens;
        cfg.method='pcc';
        cfg.pcc.fixedori       = 'yes';
        cfg.pcc.lambda        = '5%';
        cfg.pcc.projectnoise  = 'yes';
        cfg.pcc.keepfilter    = 'yes';
        cfg.grid=lf;
        cfg.vol=headmodel;
        cfg.channel = chans_included;
        sourceAll=ft_sourceanalysis(cfg, freqAll);

        % Compute whole-brain source using the pre-computed filter
        cfg=[];
        cfg.frequency = 5;
        cfg.keeptrials = 'yes';
        cfg.grad = sens;
        cfg.method='pcc';
        cfg.pcc.fixedori       = 'yes';
        cfg.pcc.lambda        = '5%';
        cfg.pcc.projectnoise  = 'yes';
        cfg.grid=lf;
        cfg.grid.filter       = sourceAll.avg.filter;
        cfg.vol=headmodel;
        cfg.channel = chans_included;
        sourcePre=ft_sourceanalysis(cfg, freqPre);
        sourcePost=ft_sourceanalysis(cfg, freqPost);

        % Clear some variables
        clear freqAll freqPost freqPre Dcum D dataAll dataPost dataPre

        % Make sure your field positions match the template grid
        sourcePre.pos=template_grid.pos;
        sourcePost.pos=template_grid.pos;

        pos = [40 -58 36];  % co-ordinate of interest within right TPJ

        % Plot position on MNI brain for sanity
        mri = ft_read_mri('D:\fieldtrip-20160208\template\anatomy\single_subj_T1.nii');

        %         cfg = [];
        %         cfg.location = pos;
        %         figure; ft_sourceplot(cfg, mri); drawnow; %Fig3

        % compute the nearest grid location to your MNI co-ordinate
        dif = sourcePre.pos;
        dif(:, 1) = dif(:, 1)-pos(1);
        dif(:, 2) = dif(:, 2)-pos(2);
        dif(:, 3) = dif(:, 3)-pos(3);
        dif = sqrt(sum(dif.^2, 2));
        %refindx = which number voxel shall we take as a reference
        [distance, refindx] = min(dif);

        % Connectivity analysis - for more options see:
        % http://www.fieldtriptoolbox.org/reference/ft_connectivityanalysis
        cfg = [];
        cfg.method = 'coh';
        cfg.complex = 'imag'; %can change to 'real'
        cfg.refindx = refindx;
        source_coh_Pre = ft_connectivityanalysis(cfg, sourcePre);
        source_coh_Post = ft_connectivityanalysis(cfg, sourcePost);

        % the output contains both the actual source position, as well as the position of the reference
        % this is ugly and will probably change in future FieldTrip versions
        orgpos = source_coh_Pre.pos(:, 1:3);
        refpos = source_coh_Pre.pos(:, 4:6);
        source_coh_Pre.pos = orgpos;

        orgpos = source_coh_Post.pos(:, 1:3);
        refpos = source_coh_Post.pos(:, 4:6);
        source_coh_Post.pos = orgpos;

        % SAVE
        save(sprintf('sourcePre_imag_coherence_visual_%s',condition{con}), 'source_coh_Pre', '-v7.3');
        save(sprintf('sourcePost_imag_coherence_visual_%s',condition{con}), 'source_coh_Post', '-v7.3');

    end
end

%% Load in data, baseline correct and add to one of two arrays -
%% grandavgA (LR_hard) or grandavgB (LR_easy)

cd D:\\pilot\\Group\\PS

for i=1:length(subject)
    % Load your LR_hard coherence data
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\sourcePost_imag_coherence_visual_LR_hard.mat',subject{i}))
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\sourcePre_imag_coherence_visual_LR_hard.mat',subject{i}))

    % Baseline Correct Coherence Values
    cfg = [];
    cfg.parameter = 'cohspctrm';
    cfg.operation = 'subtract';
    source_coh_Post_hard=ft_math(cfg,source_coh_Post,source_coh_Pre);

    % Keep track of Subject ID
    source_coh_Post_hard.subject = subject{i};
    % Add to grandavgA
    grandavgA{i} = source_coh_Post_hard; disp(['Added Subject ' subject{i}]);
end


for i=1:length(subject)
    % Load your LR_easy coherence data
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\sourcePost_imag_coherence_visual_LR_easy.mat',subject{i}))
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\sourcePre_imag_coherence_visual_LR_easy.mat',subject{i}))

    % Baseline Correct Coherence Values
    cfg = [];
    cfg.parameter = 'cohspctrm';
    cfg.operation = 'subtract';
    source_coh_Post_easy=ft_math(cfg,source_coh_Post,source_coh_Pre);


    % Keep track of Subject ID
    source_coh_Post_easy.subject = subject{i};
    % Add to grandavgB
    grandavgB{i} = source_coh_Post_easy; disp(['Added Subject ' subject{i}]);
end

%% STATS!
cfg=[];
cfg.dim         = grandavgA{1}.dim;
cfg.method      = 'montecarlo';
cfg.statistic   = 'ft_statfun_depsamplesT';
cfg.parameter   = 'cohspctrm';
cfg.correctm    = 'cluster';
cfg.computecritval = 'yes';
cfg.numrandomization = 1000;
cfg.tail        = 0;    % Two sided testing

% Design Matrix
nsubj=numel(grandavgA);
cfg.design(1,:) = [1:nsubj 1:nsubj];
cfg.design(2,:) = [ones(1,nsubj) ones(1,nsubj)*2];
cfg.uvar        = 1; % row of design matrix that contains unit variable (in this case: subjects)
cfg.ivar        = 2; % row of design matrix that contains independent variable (the conditions)

[stat] = ft_sourcestatistics(cfg,grandavgA{:}, grandavgB{:});

%save('stat','stat','-v7.3')

% Show raw source level statistics
cfg               = [];
cfg.method        = 'ortho';
cfg.funparameter  = 'stat';
cfg.location = 'max';
%cfg.maskparameter = 'mask';%turn on to show mask
cfg.funcolormap = 'jet';
ft_sourceplot(cfg,stat);

%% Interpolate onto SPM T1 brain
mri = ft_read_mri('D:\fieldtrip-20160208\template\anatomy\single_subj_T1.nii');

cfg              = [];
cfg.voxelcoord   = 'no';
cfg.parameter    = 'stat';
cfg.interpmethod = 'nearest';
statint  = ft_sourceinterpolate(cfg, stat, mri); %your FT variable corresponding to the subject specific nifti
cfg.parameter    = 'mask';
maskint  = ft_sourceinterpolate(cfg, stat,mri);
statint.mask = maskint.mask;

%% Plot interpolated results
cfg               = [];
%cfg.method        = 'slice';
cfg.funparameter  = 'stat';
cfg.maskparameter = 'mask';
cfg.location = 'max';
cfg.funcolormap = 'jet';
%cfg.funcolorlim = [-6 6]
%cfg.opacitymap    = 'rampup'
%cfg.opacitylim    = [-6 6];
ft_sourceplot(cfg,statint);

%% Export to nifti
% Run this if you want to export the clusters rather than the raw stats
statint.stat(isnan(statint.stat)) = 0;
statint.stat = (statint.stat(:).*statint.mask(:)) %masks

% Use ft_sourcewrite to export to nifti
cfg = [];
cfg.filetype = 'nifti';
cfg.filename = 'group_PS_coherence_stats_theta_visual';
cfg.parameter = 'stat';
ft_sourcewrite(cfg,statint);
```
(Dependencies: MATLAB, [Fieldtrip Toolbox](http://www.fieldtriptoolbox.org/))

Please see http://bugzilla.fieldtriptoolbox.org/show_bug.cgi?id=3029 for discussion about a fix to ft_sourceanalysis for the PCC method.
