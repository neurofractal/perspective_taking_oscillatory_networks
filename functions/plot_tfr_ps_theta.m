function plot_tfr_ps_theta(data_in,subject,var_name)    
cfg = [];
cfg.layout       = 'neuromag306cmb.lay';
cfg.baseline     = [-0.6 -0.0];
cfg.baselinetype = 'absolute';
cfg.xlim         = [0.0 0.65];
cfg.zlim = 'maxabs';
cfg.ylim         = [3 6];
cfg.interactive = 'yes';
cfg.marker       = 'on';
h = figure
subplot(2,1,1); ft_topoplotTFR(cfg, data_in); colormap('jet');
title(sprintf('Theta: subject %s',subject))
cfg.xlim         = [-0.5 1.5];
cfg.zlim = 'maxabs';
cfg.ylim         = [0 8];
cfg.layout       = 'neuromag306cmb.lay';
cfg.channel = 'MEG2042+2043'
subplot(2,1,2); ft_singleplotTFR(cfg,data_in);colormap('jet');
set(h,'Name',sprintf('%s for subject %s',var_name,subject))

saveas(gcf,sprintf('Theta plot for subject %s; condition %s.png',subject,var_name))
end