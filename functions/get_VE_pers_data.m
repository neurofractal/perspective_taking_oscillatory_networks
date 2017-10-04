%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function calculates a VE time-series at a specific MNI co-ordinate
% from the perspective-taking data (1 condition) using an LCMV beamformer.
%
% INPUTS:
% - subject code
% - condition (LR_hard, LR_easy, VO_hard, VO_easy)
% - coord : MNI co-ordinate of interest
% - area : area label (TPJ, ACC, PFC)
% OUTPUS:
% - virtualchannel_raw = Virtual Electrode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [virtualchannel_raw] = get_VE_pers_data(subject, condition, coord)

    % Loads correct data from specified condition
    load(sprintf('D:\\pilot\\%s\\PS\\data_%s.mat',subject,condition));
    % Loads variables needed for source analysis
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\mri_realigned.mat',subject))
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\sens.mat',subject))
    load(sprintf('D:\\pilot\\%s\\PS\\sourceloc\\seg.mat',subject))
    
    %% CD to correct place
    mkdir((sprintf('D:\\pilot\\%s\\PS\\VE',subject)));
    cd(sprintf('D:\\pilot\\%s\\PS\\VE',subject))
    
    %% Specify channels to analyse
    chans_included = {'MEGGRAD', '-MEG0322', '-MEG2542','-MEG0111','-MEG0532'};
    
    %% House keeping for later calls
    data_clean = eval(['data_' condition]);
    
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
    data_clean_200 = data_fix;
    
    % Limit to -1s to 1.5s either side
    cfg = [];
    cfg.toilim = [-1 1.5];
    data_clean_200 = ft_redefinetrial(cfg, data_clean_200);
    
    %% Do your timelock analysis on all the data
    cfg = [];
    cfg.covariance = 'yes'; % compute the covariance for single trials, then average
    %cfg.preproc.demean = 'yes';             % the PCA cleanup shifted the baseline
    %cfg.preproc.baselinewindow = [-Inf 0];  % reapply the baseline correction
    cfg.keeptrials = 'yes';
    timelock1 = ft_timelockanalysis(cfg, data_clean_200);
    
    cfg = [];
    cfg.covariance = 'yes'; % compute the covariance
    timelock2 = ft_timelockanalysis(cfg, timelock1);
    
    figure
    plot(timelock2.time, timelock2.avg)
    %% Create subject specific grid warped to MNI space
    % Load template sourcemodel
    load('D:\fieldtrip-20160208\template\sourcemodel\standard_sourcemodel3d5mm.mat');
    template_grid = sourcemodel;
    template_grid = ft_convert_units(template_grid,'mm')
    clear sourcemodel;
    
    cfg        = [];
    cfg.method = 'singleshell';
    headmodel  = ft_prepare_headmodel(cfg, seg);
    
    % create the subject specific grid, using the tem-
    % plate grid that has just been created
    cfg                = [];
    cfg.grid.warpmni   = 'yes';
    cfg.grid.template  = template_grid;
    cfg.grid.nonlinear = 'yes'; % use non-linear normalization
    cfg.mri            = mri_realigned;
    cfg.grid.unit      ='mm';
    %cfg.inwardshift = -1.5;
    grid               = ft_prepare_sourcemodel(cfg);
    
    % make a figure of the single subject headmodel, and grid positions
    figure; hold on;
    ft_plot_vol(headmodel, 'facecolor', 'g', 'facealpha', 0.9);
    ft_plot_mesh(grid.pos(grid.inside,:))
    ft_plot_sens(sens, 'style', 'r*')
    
    %% Compute VE timeseries using LCMV at a location
    % This bit loads the subject specific pos from a file called
    % VE_coord_visual.m. Alternatively you manually specifiy pos = [X Y Z].
    pos = coord;
    disp(pos)
    
    % Warp the MNI co-orindate to the subject specific grid.pos.
    % This is important and took me a while to get my head around!
    % ft_warp_apply is using the warping parameters computed
    % during the non-linear transform from subject specific to MNI space.
    posback=ft_warp_apply(grid.params,pos,'sn2individual')
    gridpos= ft_warp_apply(pinv(grid.initial),posback)
    
    % Plot position on MNI brain for sanity
    mri = ft_read_mri('D:\fieldtrip-20160208\template\anatomy\single_subj_T1.nii');
    
    cfg = [];
    cfg.location = pos;
    figure; ft_sourceplot(cfg, mri);
    set(gcf,'name',sprintf('Location of the VE for subject: %s',subject))
    saveas(gcf,'VE_pos.png');
    
    % Compute LCMV
    cfg = [];
    cfg.grid.pos = gridpos; %NOT pos as this is MNI co-ordinate
    cfg.grid.unit = 'mm';
    cfg.headmodel  = headmodel;
    cfg.grad = sens;
    cfg.senstype = 'MEG';
    cfg.method = 'lcmv';
    cfg.lcmv.keepfilter = 'yes';
    cfg.lcmv.projectmom = 'yes';
    cfg.normalize = 'yes';
    cfg.grid.inside = [1:1:1];
    source = ft_sourceanalysis(cfg, timelock2);
    
    % Plot the averaged timeseries
    figure
    plot(source.time, source.avg.mom{1})
    
    %% This extracts timeseries info for each trial rather than the average
    virtualchannel_raw = [];
    virtualchannel_raw.label = {'pos'};
    virtualchannel_raw.trialinfo = data_clean_200.trialinfo;
    for j=1:(length(data_clean.trialinfo))
        % note that this is the non-filtered raw data
        virtualchannel_raw.time{j}       = data_clean_200.time{j};
        virtualchannel_raw.trial{j}(1,:) = source.avg.filter{1} * data_clean_200.trial{j}(:,:);
    end

end
    