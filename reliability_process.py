#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat May  5 16:17:24 2018

@author: xuzekun
"""

import os 
import pandas as pd 
import numpy as np
import time
import math
from sklearn.metrics import mean_squared_error
import matplotlib.pyplot as plt


#####  python3 -m pip install biosppy
#this package is to auto-process the ecg signal
from biosppy.signals import ecg

######################################################################
#Reliability of bioharness heart rate

#change to the directory that contains the sas and python macros
progpath = '/Users/xuzekun/Desktop/github/statistical_signal_quality/macro'
os.chdir(progpath)
from utility import *


#change to your ADL directory
adlpath = '/Users/xuzekun/Desktop/github/statistical_signal_quality/NCSU-ADL'

#subject id numbers: correspond to the subject folder's suffix
ids = ['015','059','274','292','380','390','454','503','805','875']#'909'


#the data set that contains the bioharness and shimmer heart rate
#with known activity for each subject in the ADL data
supervised = main_reliability(ids, adlpath)

#check
#function argument should be the subset data after group by
supervised.columns
supervised.groupby(['subj']).size()
supervised.groupby(['subj','act']).size()  

#temporarily save the result to pickle
savepath='/Users/xuzekun/Desktop/github/statistical_signal_quality/'
os.chdir(savepath)
supervised.to_pickle('supervised.pickle')
#supervised = pd.read_pickle('supervised.pickle')

##################################################################
#now combine the cluster state from an unsupervised learning to the supervised data
prefix = ['15','59','274','292','380','390','454','503','805','875']
suffix = 'test.csv' #should only model the test data


#change to the directory unsupervised clustering data
unpath = '/Users/xuzekun/Desktop/github/statistical_signal_quality/NCSU-ADL/naive_classifier/'

#!!!!!!!    this one is extremely slow    !!!!!!!!!!!!!!!!
fulldata = combine_cluster_state(prefix, suffix, unpath, supervised)

#plot to check
subset = fulldata[fulldata['subj']=='015']
for ii, actname in enumerate(np.unique(subset['act'])):
    print(actname)
    plot_bpm(subset[subset['act']==actname],actname,'015')

#save to the csv file for SAS to analyze
os.chdir(savepath)
fulldata.to_csv('reliability.csv')


