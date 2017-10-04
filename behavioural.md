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

        # Remove RT cases 2SD from the median
        twostd_val = np.median(RT_list[p])+2*(np.std(RT_list[p]))       
        RT_list[p] = [x for x in RT_list[p] if x<twostd_val]
    return RT_list

## Extract RT
RT_LR_160 = extract_RT(participant_list,output,'vpt2proc', '160')
RT_LR_60 = extract_RT(participant_list,output,'vpt2proc', '60')
RT_VO_160 = extract_RT(participant_list,output,'vpt1proc', '160')
RT_VO_60 = extract_RT(participant_list,output,'vpt2proc', '60')

## Function to make a boxplot for participantxRT data for each condition
def make_boxplot_1(RT_scores,n,participant_list,title):
    plt.figure(n)
    plt.boxplot(RT_scores,labels = participant_list,showfliers=False)
    plt.title(title)
    plt.xlabel('Partipant Code')
    plt.ylabel('Reaction Time (msec)')
    plt.show()

make_boxplot_1(RT_LR_160,1,participant_list,'LR_160')
make_boxplot_1(RT_LR_60,2,participant_list,'LR_60')
make_boxplot_1(RT_VO_160,3,participant_list,'VO_160')
make_boxplot_1(RT_VO_60,4,participant_list,'VO_60')

## Get medians from each participant
def get_group_data(participant_list,RT_scores):
    data_median = []
    for nnn in range(0,len((participant_list)),1):
        data_median.append(np.median(RT_scores[nnn]))
    return data_median

data_LR_160_median = get_group_data(participant_list,RT_LR_160)
data_LR_60_median = get_group_data(participant_list,RT_LR_60)
data_VO_160_median = get_group_data(participant_list,RT_VO_160)
data_VO_60_median = get_group_data(participant_list,RT_VO_60)

data = [data_LR_160_median,data_LR_60_median, data_VO_160_median, data_VO_60_median]

## Show Bar-Graph
labels = ('LR_160','LR_60','VO_160','VO_60')
group_medians = [np.median(data[0]),np.median(data[1]),np.median(data[2]),np.median(data[3])]
y_pos = np.arange(len(group_medians))
plt.figure(5)
plt.bar(y_pos, group_medians, align='center', alpha=0.4)
plt.xticks(y_pos, labels)
plt.ylabel('RT (ms)')
plt.title('Group median RTs')

plt.show()

## Beeswarm Plot

plt.rcParams["font.family"] = "arial"

from beeswarm import *               

beeswarm([[],data_LR_160_median,data_LR_60_median,data_VO_160_median,data_VO_60_median], method="swarm", labels=["","data_LR_160", "data_LR_60","data_VO_160","data_VO_60"], col=["red","red","red","red","red"])
plt.ylabel('RT (msec)',fontsize = 15)
plt.tick_params(axis='both', which='major', labelsize=15)
bp = plt.boxplot(data,labels = ['LR-160','LR-60','VO-160','VO-60'],showfliers=False)

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

This boxplot to shows participant’s median reaction time (RT) in milliseconds for the 4 conditions of the perspective taking task. Statistical analysis was performed using SPSS v21.

As in Kessler & Rutherford (2010) performance in the LR-160 condition was accompanied by significantly longer reaction time (RT) compared with all other experimental conditions.
