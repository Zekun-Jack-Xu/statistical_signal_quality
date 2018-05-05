#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat May  5 18:01:48 2018

@author: xuzekun
"""


import re
import os 
import pandas as pd 
import numpy as np
import time
import math

#change to the directory that contains the sas and python macros
progpath = '/Users/xuzekun/Desktop/github/statistical_signal_quality/macro'
os.chdir(progpath)
from utility import *

#change to the directory for ADL data
adlpath = '/Users/xuzekun/Desktop/research/paper5/data/NCSU-ADL'
#change to the directory for anomaly data
anomalypath = '/Users/xuzekun/Desktop/github/statistical_signal_quality/ADLData-HR-Anomoly'

#change to the correpsonding annotation filenames in adl data
adlsuffix = ['/Subject015/Annotations.csv','/Subject059/Annotations.csv',
           '/Subject274/Annotations.csv','/Subject292/Annotations.csv',
           '/Subject380/Annotations.csv','/Subject390/Annotations.csv',
           '/Subject454/Annotations.csv','/Subject503/Annotations.csv',
           '/Subject805/Annotations.csv','/Subject875/Annotations.csv']

#change to the corresponding anomaly filenames in the anomaly data
anomalysuffix = ['/15anomolies.csv','/59anomolies.csv','/274anomolies.csv',
           '/292anomolies.csv','/380anomolies.csv','/390anomolies.csv',
           '/454anomolies.csv','/503anomolies.csv','/805anomolies.csv',
           '/875anomolies.csv']

i=0
for part1, part2 in zip(adlsuffix, anomalysuffix):
    
    tempdata = anomaly_count(part1, part2, adlpath, anomalypath)
    if i == 0:
        anomaly = tempdata
        i += 1
    else:
        anomaly = pd.concat([anomaly, tempdata])
        i += 1

        
anomaly.reset_index(inplace=True)
del anomaly['index']

#saving directory
savepath='/Users/xuzekun/Desktop/github/statistical_signal_quality/'
os.chdir(savepath)
anomaly.to_csv("anomaly.csv",index=False)


#check
anomaly.groupby(['subject','Label'])['anomaly_freq','minutes'].sum()