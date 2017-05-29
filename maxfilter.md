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
