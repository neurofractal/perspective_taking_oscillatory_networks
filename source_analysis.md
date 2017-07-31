## Source Analysis

We performed source analysis in the theta band using a DICS beamformer 

Source localisation was conducted using Dynamical Imaging of Coherent Sources (DICS, [Gross et al., 2001](http://www.pnas.org/content/98/2/694.full)), which applies a spatial filter to the MEG data at each grid point, in order to maximise signal from that location whilst attenuating signals elsewhere. The spatial filter was calculated from the cross-spectral densities for a time–frequency tile centred on the effects found at sensor level (3-6Hz; 0–650ms; gradiometer channels only). Beamforming approaches have been shown to reduce the influence of external artefacts (e.g. EOG, ECG and muscle activity) by localising these outside the brain ([Herdman & Cheyne, 2009](https://books.google.com.au/books?hl=en&lr=&id=-l-GDQdadPMC&oi=fnd&pg=PA99&dq=Herdman+%26+Cheyne,+2009&ots=JenpAKw_RU&sig=djk76Yt7t-80gYjWb9Sr_wGNHqM#v=onepage&q=Herdman%20%26%20Cheyne%2C%202009&f=false); [Hillebrand & Barnes, 2005](http://onlinelibrary.wiley.com/doi/10.1002/hbm.20102/full)). For all analyses, a common filter across baseline and active periods was used and a regularisation parameter of lambda 5% was applied. 

Script: *group_beamformer_2_multiplesubject_PS.m*

```matlab
%% Specify subject list, good channals and condition labels
subject = sort({'XX','XY','XZ'...});

% Only include the gradiometers and remove bad channels
chans_included = {'MEGGRAD', '-MEG0322', '-MEG2542','-MEG0111','-MEG0532'};

% Condition List
condition = {'LR_hard','LR_easy','VO_easy','VO_hard'};

%% Loop for all subjects & all conditions
for i=1:length(subject)
    %% Load variable required for source analysis
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\mri_realigned.mat',subject{i}))
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\sens.mat',subject{i}))
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\seg.mat',subject{i}))
    
    %% Create leadfields in subject's brain warped to MNI space
    % Load template sourcemodel
    load('D:\fieldtrip-20160208\template\sourcemodel\standard_sourcemodel3d8mm.mat');
    template_grid = sourcemodel;
    template_grid = ft_convert_units(template_grid,'mm')
    clear sourcemodel;
    
    % construct the volume conductor model (i.e. head model) for each
    % subject
    cfg        = [];
    cfg.method = 'singleshell';
    headmodel  = ft_prepare_headmodel(cfg, seg);
    
    % create the subject specific grid, using the template grid that has
    % just been created
    cfg                = [];
    cfg.grid.warpmni   = 'yes';
    cfg.grid.template  = template_grid;
    cfg.grid.nonlinear = 'yes'; % use non-linear normalization
    cfg.mri            = mri_realigned;
    cfg.grid.unit      ='mm';
    grid               = ft_prepare_sourcemodel(cfg);
    
    % make a figure of the single subject headmodel, and grid positions
    figure; hold on;
    ft_plot_vol(headmodel, 'edgecolor', 'none', 'facesourceloc', 0.4);
    ft_plot_mesh(grid.pos(grid.inside,:));
    ft_plot_sens(sens, 'style', 'r*')
    
    % create leadfield
    cfg = [];
    cfg.channel = chans_included;
    cfg.grid = grid;
    cfg.vol = headmodel;
    cfg.grad = sens;
    cfg.normalize = 'yes';
    
    lf = ft_prepare_leadfield(cfg)
    
    %% Now perform DICS using prepared leadfields for all 4 conditions
    for con = 1:length(condition)
        %% Load the required variables you computed earlier
        load(sprintf('D:\\pilot\\%s\\PS\\data_%s.mat',subject{i},condition{con}))
        
        %% CD to correct place
        cd(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\',subject{i}))
        
        %% Load in data variable of interest
        data_clean = eval(sprintf('data_%s',condition{con}));
        
        %% Compensate for Maxfilter & keep the manuualy keep the rank of the data under 64
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
        data_clean_250 = ft_resampledata(cfg,data_fix);
        
        %% Cut out windows of interest
        cfg = [];
        cfg.toilim = [-0.65 0];
        dataPre = ft_redefinetrial(cfg, data_clean_250);
        
        cfg.toilim = [0 0.65];
        dataPost = ft_redefinetrial(cfg, data_clean_250);
        
        cfg.toilim = [-0.65 0.65];
        dataAll = ft_redefinetrial(cfg, data_clean_250);
        
        %% Do sensor-level frequency analysis
        cfg = [];
        cfg.grad = sens;
        cfg.taper = 'hanning'; 
        cfg.method    = 'mtmfft';
        cfg.output    = 'powandcsd';
        cfg.foilim    = [3 6];
        cfg.pad = 4;
        freqAll = ft_freqanalysis(cfg, dataAll);
        freqPre = ft_freqanalysis(cfg, dataPre);
        freqPost = ft_freqanalysis(cfg, dataPost);
        
        %% Do ya beamforming
        % Source reconstruction for the whole trial
        cfg=[];
        cfg.grad = sens;
        cfg.method='dics';
        cfg.dics.lambda       = '5%';
        cfg.dics.projectnoise = 'yes';
        cfg.grid=lf;
        cfg.vol=headmodel;
        cfg.keepfilter = 'yes';
        cfg.channel = chans_included;
        sourceAll=ft_sourceanalysis(cfg, freqAll);
        
        % DICS for your conditions of interest using the common filter
        % computed aboce.
        cfg=[];
        cfg.grad = sens;
        cfg.method='dics';
        cfg.dics.lambda       = '5%';
        cfg.dics.projectnoise = 'yes';
        cfg.grid=lf;
        cfg.grid.filter = sourceAll.avg.filter;
        cfg.vol=headmodel;
        cfg.keepfilter='no';
        cfg.channel = chans_included; 
        sourcePre=ft_sourceanalysis(cfg, freqPre);
        sourcePost=ft_sourceanalysis(cfg, freqPost);
        
        % Make sure your field positions match the template grid
        sourcePre.pos=template_grid.pos; % right(?)
        sourcePost.pos=template_grid.pos; % right(?)
        
        % SAVE
        save(sprintf('sourcePre_%s',condition{con}), 'sourcePre', '-v7.3');
        save(sprintf('sourcePost_%s',condition{con}), 'sourcePost', '-v7.3');
        
        % Compute the power difference between baseline and active period
        cfg = [];
        cfg.parameter = 'avg.pow';
        cfg.operation = '((x1-x2)./x2)*100';
        sourceR=ft_math(cfg,sourcePost,sourcePre);
        
        % Interpolate
        mri = ft_read_mri('D:\fieldtrip-20160208\template\anatomy\single_subj_T1.nii');
        
        cfg              = [];
        cfg.voxelcoord   = 'no';
        cfg.parameter    = 'pow';
        cfg.interpmethod = 'nearest';
        sourceI  = ft_sourceinterpolate(cfg, sourceR, mri);
        
        % Plot + Save
        cfg = [];
        cfg.funparameter = 'pow'
        cfg.location = 'max';
        ft_sourceplot(cfg,sourceI)
        colormap(jet)
        set(gcf,'name',sprintf('%s>Baseline Subject: %s',condition{con},subject{i}))
        saveas(gcf,sprintf('SourceI_%s.png',condition{con}));
        
        clear data_clean data_fix sourceR sourceI sourcePre sourcePost
        clc
    end
    %% Now we calculate Left/Right 160 versus Visible Occluded 160
    
    load sourcePost_LR_hard.mat
    load sourcePre_LR_hard.mat
    
    % Baseline correct LR_hard
    cfg = [];
    cfg.parameter = 'avg.pow';
    cfg.operation = '((x1-x2)./x2)*100';
    sourcePost_LRhard_bc =ft_math(cfg,sourcePost,sourcePre);
    
    load sourcePost_LR_easy.mat
    load sourcePre_LR_easy.mat
    
    % Baseline correct LR_easy
    cfg = [];
    cfg.parameter = 'avg.pow';
    cfg.operation = '((x1-x2)./x2)*100';
    sourcePre_LReasy_bc =ft_math(cfg,sourcePost,sourcePre);
    
    % Take LR_hard activity away from LR_easy
    cfg = [];
    cfg.parameter = 'avg.pow';
    cfg.operation = 'subtract';
    sourceR=ft_math(cfg,sourcePost_LRhard_bc,sourcePre_LReasy_bc);
    
    % Interpolate onto MRI with atlas
    mri = ft_read_mri('D:\fieldtrip-20160208\template\anatomy\single_subj_T1.nii');
    
    cfg              = [];
    cfg.voxelcoord   = 'no';
    cfg.parameter    = 'pow';
    cfg.interpmethod = 'nearest';
    sourceI  = ft_sourceinterpolate(cfg, sourceR, mri);
    
    cfg=[];
    cfg.method = 'ortho';
    cfg.funparameter = 'pow';
    cfg.funcolormap    = 'jet';
    ft_sourceplot(cfg,sourceI);
    set(gcf,'name',sprintf('160 vs 60 L/R Subject = %s',subject{i}))
    saveas(gcf,'160 vs 60 L_R.png')
    
    clear seg sens mri_realigned lf grid template_grid 
end
```


Left/Right and Visible/Occluded theta power whole-brain maps are then loaded, baseline corrected and statistically compared using non-parametric cluster statistics.
```matlab
% For each condition I am loading in pre + post soure localisation
% variables and subtracting the post-grating power frome pre-grating power

grandavg_LR_hard = []; % LR_hard

for i=1:length(subject)
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\sourcePost_LR_hard.mat',subject{i}))
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\sourcePre_LR_hard.mat',subject{i}))
    
    cfg = [];
    cfg.parameter = 'avg.pow';
    cfg.operation = 'subtract';
    sourceR=ft_math(cfg,sourcePost,sourcePre);
    
    sourceR.subject = subject{i}; 
    grandavg_LR_hard{i} = sourceR; disp(['Added Subject ' subject{i}]);
end

clear alldata cfg sourceR 

grandavg_LR_easy = []; % LR_easy

for i=1:length(subject)
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\sourcePost_LR_easy.mat',subject{i}))
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\sourcePre_LR_easy.mat',subject{i}))
    
    cfg = [];
    cfg.parameter = 'avg.pow';
    cfg.operation = 'subtract';
    sourceR=ft_math(cfg,sourcePost,sourcePre);
    
    sourceR.subject = subject{i}; 
    grandavg_LR_easy{i} = sourceR; disp(['Added Subject ' subject{i}]);
end

clear alldata cfg sourceR 

grandavg_VO_hard = []; % VO_hard

for i=1:length(subject)
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\sourcePost_VO_hard.mat',subject{i}))
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\sourcePre_VO_hard.mat',subject{i}))
    
    cfg = [];
    cfg.parameter = 'avg.pow';
    cfg.operation = 'subtract';
    sourceR=ft_math(cfg,sourcePost,sourcePre);
    
    sourceR.subject = subject{i}; 
    grandavg_VO_hard{i} = sourceR; disp(['Added Subject ' subject{i}]);
end

clear alldata cfg sourceR 

grandavg_VO_easy = []; % VO_easy

for i=1:length(subject)
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\sourcePost_VO_easy.mat',subject{i}))
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\sourcePre_VO_easy.mat',subject{i}))
    
    cfg = [];
    cfg.parameter = 'avg.pow';
    cfg.operation = 'subtract';
    sourceR=ft_math(cfg,sourcePost,sourcePre);
    
    sourceR.subject = subject{i}; 
    grandavg_VO_easy{i} = sourceR; disp(['Added Subject ' subject{i}]);
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% STATS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Run Statistics
% run statistics over subjects
cfg=[];
cfg.dim         = grandavg_LR_hard{1}.dim;
cfg.method      = 'montecarlo';
cfg.statistic   = 'ft_statfun_depsamplesT';
cfg.parameter   = 'pow';
cfg.correctm    = 'cluster';
cfg.computecritval = 'yes';
cfg.numrandomization = 1000;
cfg.tail        = 0;    % Two sided testing

% Design Matrix
nsubj=numel(grandavg_LR_hard);
cfg.design(1,:) = [1:nsubj 1:nsubj];
cfg.design(2,:) = [ones(1,nsubj) ones(1,nsubj)*2];
cfg.uvar        = 1; % row of design matrix that contains unit variable (in this case: subjects)
cfg.ivar        = 2; % row of design matrix that contains independent variable (the conditions)

% Perform statistical analysis separsetly for LR & VO conditions
[stat_LR] = ft_sourcestatistics(cfg,grandavg_LR_hard{:}, grandavg_LR_easy{:});
[stat_VO] = ft_sourcestatistics(cfg,grandavg_VO_hard{:}, grandavg_VO_easy{:});
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
```

The results are interpolated onto the standard SPM T1 brain and exported to .nii and .gii (Human Connectome Project) formats.

```matlab
%% Interpolate onto SPM T1 brain
mri = ft_read_mri('D:\fieldtrip-20160208\template\anatomy\single_subj_T1.nii');

cfg              = [];
cfg.voxelcoord   = 'no';
cfg.parameter    = 'stat';
cfg.interpmethod = 'nearest';
statint  = ft_sourceinterpolate(cfg, stat_LR, mri); %your FT variable corresponding to the subject specific nifti
cfg.parameter    = 'mask';
maskint  = ft_sourceinterpolate(cfg, stat_LR,mri);
statint.mask = maskint.mask;

%% Plot interpolated results
cfg               = [];
cfg.funparameter  = 'stat';
cfg.maskparameter = 'mask';
cfg.location = 'max';
cfg.funcolormap = 'jet';
ft_sourceplot(cfg,statint);

%% Export to nifti
% Run this if you want to export the clusters rather than the raw stats
statint.stat(isnan(statint.stat)) = 0;
statint.stat = (statint.stat(:).*statint.mask(:)) %masks

% Use ft_sourcewrite to export to nifti
cfg = [];
cfg.filetype = 'nifti';
cfg.filename = 'group_PS_stats_3_6Hz_clustered';
cfg.parameter = 'stat';
ft_sourcewrite(cfg,statint);
```
Dependencies: [Fieldtrip Toolbox](http://www.fieldtriptoolbox.org/)
