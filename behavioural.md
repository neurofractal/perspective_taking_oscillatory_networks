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
