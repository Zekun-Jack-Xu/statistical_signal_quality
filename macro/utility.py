#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Fri Jan 26 13:32:02 2018

@author: xuzekun

purpose: 
    1. read the bioharness and shimmer ADL data
    2. convert the shimmer ecg to heart rate
    3. output
"""


import os 
import pandas as pd 
import numpy as np
import time
import math
from sklearn.metrics import mean_squared_error
import matplotlib.pyplot as plt
import re

#####  python3 -m pip install biosppy
#this package is to auto-process the ecg signal
from biosppy.signals import ecg


#change to your ADL directory
path = '/Users/xuzekun/Desktop/github/statistical_signal_quality/NCSU-ADL'
os.chdir(path)

#subject id numbers: correspond to the subject folder's suffix
ids = ['015','059','274','292','380','390','454','503','805','875']#'909'


#######################################################################
'''
function to gather the synced bioharness and shimmer heart rate in the 
same data set according to a certain row of start and end time in the Annotations.csv
arguments:
    row --- row number in the label data frame (from 0)
    bh --- the data frame of bioharness heart rate
    sh --- the data frame of shimmer ecg
    label --- the data frame for Annotations.csv
    subj --- subject id
    rowstart --- series id within the subject
'''
def process1(row, bh, sh, label, ecgnames,\
             subj, rowstart=0):
    
    '''subset bh and sh data according to the row in label'''
    act = label.iloc[row,2]
    start = label.iloc[row,0]
    end  = label.iloc[row,1]
    
    bhcrit = (bh['TimeSync_min'] > start)&(bh['TimeSync_min']<end) 
    bh1 = bh.where(bhcrit).dropna()
    bh1['act'] = act
    bh1['bh'] = 1
    bh1['id'] = row + rowstart
    bh1['subj'] = subj
    shcrit = (sh['TimeSync_min'] > start)&(sh['TimeSync_min']<end)
    sh1 = sh.where(shcrit).dropna()
    sh1['act'] = act
    sh1['id'] = row + rowstart
    sh1['subj'] = subj
    
    '''sampling frequency'''
    fs1 = 1/(bh1['TimeSync_min'].diff().values[1] * 60) 
    fs2 = 1/(np.mean(sh1['TimeSync_min'].diff().values[1:sh1.shape[0]]) * 60)
    
    '''alternatively, dictionary of dataframes: c_dict = {}; c_dict['a'] = together1'''
     
    for index, x in enumerate(ecgnames):
        '''get the bpm from ecg'''
        ecg1 = sh1[x].values
        out1 = ecg.ecg(signal=ecg1, sampling_rate=fs2, show=False)
        time = out1['heart_rate_ts']/60
        rate = out1['heart_rate']
        
        '''match the time point between bh and sh
        vertically union the two data sets and sort by time'''
        newsh = pd.DataFrame({'TimeSync_min':time+start,x:rate,
                              'act':np.repeat(act,len(rate)),
                              'id':np.repeat(row,len(rate))})
    
        together = pd.concat([bh1,newsh])
        together.sort_values(['TimeSync_min'], ascending=[1],inplace=True)
        together.reset_index(inplace=True)
        del together['index']
    
        '''average of the nearest before and after'''
        for i in range(1,together.shape[0]):
            if together['bh'][i] == 1 and i>0 and i<together.shape[0]-1:
                together.loc[i,x] = (together.loc[i-1,x] +\
                            together.loc[i+1,x])/2

        together1 = together.dropna()
        #together1.loc[:,'diff_'+x] = together1.loc[:,x] - together1.loc[:,'hr']
        
        if index == 0:
            together2 = together1
        else:
            together2 = pd.merge(together2, together1, how='inner',\
                                 on=['TimeSync_min','subj','act','id','bh','br','hr'])
    
    
    return together2


#compute the median of three heart rate signals out of the 4 
#which are closest to the raw median
def median2level(df):
    median1 = np.median(df)
    index = np.argmax(abs(df - median1))
    del df[index]
    median2 = np.median(df)
    return median2  
#a=tempdf.apply(median2level,axis=1)
#b=np.median(tempdf,axis=1)
#np.vstack([a,b])


'''
main function to preprocess the shimmer ecg, and then combine
the shimmer and bioharness heart rate for each subject in the same big data
arguments:
    ids --- list of ids, corresponding the subject subfolder's suffix
    path --- path of the ADL data
    
'''
def main_reliability(ids, path):

    rowstart = 0
    for thisid,thisname in enumerate(ids):
        print(thisid+1,'of',len(ids))
    
        os.chdir(path+'/Subject'+thisname)
        
        label = pd.read_csv("Annotations.csv")
        bh = pd.read_csv("BH_Summary.csv")
        bh.columns = ['TimeSync_min','hr','br']
        sh = pd.read_csv("SH_Chest.csv")
        col = ['TimeSync_min',' ECGLA-RA_mV',' ECGLL-LA_mV',' ECGLL-RA_mV',' ECGVx_mV']
        sh = sh[col]
       
    
        ecgnames = ['ecglara','ecgllla','ecgllra','ecgvx']
        sh.columns = ['TimeSync_min','ecglara','ecgllla','ecgllra','ecgvx']
        
        for rr in range(label.shape[0]):
            if rr == 0:
                data1 = process1(rr,bh,sh,label,ecgnames,thisname,rowstart)
            else:
                temp1 = process1(rr,bh,sh,label,ecgnames,thisname,rowstart)
                data1 = pd.concat([data1, temp1])
        
        
        ###throw away the channel farthest from the median
        ###compute the median for the remaining
        
        temphr = data1.loc[:,ecgnames]
        
        truehr = temphr.apply(median2level,axis=1)
        
        data1['truehr'] = truehr
        
        for ii,nn in enumerate(ecgnames):
            data1['diff_'+nn] = data1['truehr'] - data1[nn]
        
        data1['diff_bh'] = data1['truehr'] - data1['hr']
        
     
        if thisid == 0:
            result = data1
        else:
            result = pd.concat([result,data1])
            
        rowstart += label.shape[0]
        
    result['logy'] = np.log(np.abs(result['diff_bh']))   
    
    return result

#save as a pickle file
#os.chdir(path)
#result.to_pickle('ten_sub_hr_median3.pickle')

'''
function to combine the cluster state learned from some unsupervised model
with the original 
olddata refers to the data frame with actual activity label
'''

def combine_cluster_state(prefix, suffix, path, olddata):
    
    for i in range(len(prefix)):
        filename = path + prefix[i] + suffix 
        thiscsv = pd.read_csv(filename, header=None)
        thiscsv.columns = ['TimeSync_min','f1','f2','f3','pred_label','true_label']
        min_time = np.min(thiscsv.TimeSync_min)
        max_time = np.max(thiscsv.TimeSync_min)
        
        subset = olddata[olddata['subj']==ids[i]]
        cond = (subset['TimeSync_min']>min_time) & (subset['TimeSync_min']<max_time)
        subset = subset[cond]
        combined = pd.concat([subset, thiscsv])
        combined.sort_values(['TimeSync_min'], ascending=[1],inplace=True)
        combined.reset_index(inplace=True)
        del combined['index']
        del combined['f1']
        del combined['f2']
        del combined['f3']             
        
        for j in range(combined.shape[0]):
            if math.isnan(combined.true_label[j]):
                combined.true_label[j] = current_true
                combined.pred_label[j] = current_pred
            else:
                current_true = combined.true_label[j]
                current_pred = combined.pred_label[j]
        
        thiscombine = combined.dropna()
        
        if i == 0:
            full2 = thiscombine
        else:
            full2 = pd.concat([full2,thiscombine])
        
    ######################################################
    #get the series id
    
    #full2['logy'] = np.log(np.abs(full2['diff_bh']))
    full2.reset_index(inplace=True)
    del full2['index']
    del full2['id']

    #create a new column for series id corresponding to pred_label
    predid = np.ones(full2.shape[0])
    trueid = np.ones(full2.shape[0])
    current_id = 1
    current_id2 = 1
    counter = 1
    counter2 = 1

    for i in range(1,full2.shape[0]):
        cond = (full2.subj[i] == full2.subj[i-1]) &\
               (full2.pred_label[i] == full2.pred_label[i-1]) &\
               (counter <= 10)
               
        cond2 = (full2.subj[i] == full2.subj[i-1]) &\
               (full2.true_label[i] == full2.true_label[i-1]) &\
               (counter <= 10)
               
        if cond:
            predid[i] = current_id
            counter += 1
        else:
            current_id += 1
            predid[i] = current_id
            counter = 1
            
        if cond2:
            trueid[i] = current_id2
            counter2 += 1
        else:
            current_id2 += 1
            trueid[i] = current_id2

    full2['pred_id'] = predid
    full2['true_id'] = trueid
    
    
    return full2
    

##################################################
#plot the BIOHARNESS and SHIMMER bpm
def plot_bpm(data,act,subj,figsize=(10,5)):
    fig = plt.figure(figsize=figsize)
    ax1 = fig.add_subplot(111)
    a, = ax1.plot(data['hr'].values, '--', color="b",label="BH_HR")
    #aa, = ax1.plot(data['br'].values, '--', color="gray",label="BH_RR")
    b, = ax1.plot(data['ecglara'].values, '-', color="r",label="SH_LARA")
    c, = ax1.plot(data['ecgllla'].values, '-', color="g",label="SH_LLLA")
    d, = ax1.plot(data['ecgllra'].values, '-', color="k",label="SH_LLRA")
    e, = ax1.plot(data['ecgvx'].values, '-', color="y",label="SH_VX")
    ax1.legend(handles=[a,b,c,d,e])
    ax1.set_xlabel("sec")
    ax1.set_ylabel("bpm")
    ax1.set_title('Activity: ' + act + '(Subject:'+subj+')')
    plt.show()
    
    
def plot_bpm2(data,act,subj,figsize=(10,5)):
    fig = plt.figure(figsize=figsize)
    ax1 = fig.add_subplot(111)
    a, = ax1.plot(data['hr'].values, '--', color="b",label="BH_HR")
    aa, = ax1.plot(data['truehr'].values, '-', color="r",label="SH_HR")
    
    ax1.legend(handles=[a,aa])
    ax1.set_xlabel("sec")
    ax1.set_ylabel("bpm")
    ax1.set_title('Activity: ' + act + '(Subject:'+subj+')')
    plt.show()
    
#main function to get anomaly counts
def anomaly_count(adlsuffix, anomalysuffix, adlpath, anomalypath):
    
    
    suffix1 = adlsuffix
    suffix2 = anomalysuffix
    path1 = adlpath
    path2 = anomalypath
    
    subjid = re.findall(r'\d+',suffix2)[0]
    filename1 = path1 + suffix1
    lookup = pd.read_csv(filename1)
    
    filename2 = path2 + suffix2
    anomaly = pd.read_csv(filename2,header=None)
    anomaly.columns = ['obsnum1','obsnum2','etime1','etime2',
                   'Start_Time_min','Start_End_min']
    useful = anomaly[['Start_Time_min','Start_End_min']]

    together = pd.concat([lookup,useful])
    together.sort_values(['Start_Time_min'], ascending=[1],inplace=True)

    minimum = np.min(lookup.Start_Time_min)
    maximum = np.max(lookup.Start_End_min)
    filtering = (together.Start_Time_min>=minimum)&(together.Start_End_min<=maximum)
    together = together[filtering]

    together.reset_index(inplace=True)
    del together['index']

    ######################################
    nrow = together.shape[0]
    newid = np.zeros(nrow)
    nalist = pd.isnull(together['Label'])
    temp = 0

    for i in range(nrow):
        if nalist[i] == False:
            tempend = together.iloc[i, 1]
            temp += 1
            newid[i] = temp 
        else:
            if together.iloc[i,2]>tempend:
                temp += 1
                newid[i] = temp
            else:
                newid[i] = temp

    together['matchid'] = newid

    summary = pd.DataFrame(together.groupby('matchid')['Start_Time_min'].count())
    summary.reset_index(inplace=True)
    summary.columns = ['matchid','freq']

    combine2 = pd.merge(together, summary, "left", 'matchid')
    combine2.dropna(inplace=True)
    combine2['anomaly_freq'] = combine2['freq'] - 1
    combine2['minutes'] = combine2['Start_End_min'] - combine2['Start_Time_min']
    combine3 = combine2[['Label','minutes','anomaly_freq']]
    combine3['subject'] = subjid
    return combine3
################################################################
'''
import os 
import pandas as pd 
import numpy as np
import time

path = '/Users/xuzekun/Desktop/research/paper5/data/NCSU-ADL'

from sklearn.metrics import mean_squared_error
from scipy.stats import ttest_ind
from scipy.stats import levene

import matplotlib.pyplot as plt
from biosppy.signals import ecg
os.chdir(path)
d = pd.read_pickle('ten_sub_hr.pickle')

np.unique(d['id'])

grouped = d.groupby(['subj'])
grouped.size()
grouped = d.groupby(['subj','act'])
grouped.size()


    
################################################
#plot hr for each activity for this subject
#%matplotlib gtk
ids = ['015','059','274','292','380','390','454','503','805','875']#'909'

full2=d
subset = full2[full2['subj']=='015']
for ii, actname in enumerate(np.unique(subset['act'])):
    print actname
    plot_bpm2(subset[subset['act']==actname],actname,'015')
    
    
subset = full2[full2['subj']=='015']
for ii, actname in enumerate(np.unique(subset['act'])):
    print actname
    plot_bpm(subset[subset['act']==actname],actname,'015')
    
####################################
#merge with trained cluster labels





#flag periods where bioharness median < 40
check1 = d.groupby(['subj','id'])['hr'].agg({'median_bhhr':np.median,'min_bhhr':np.min})
weird = (check1['median_bhhr']<50) | (check1['min_bhhr']==0)
from collections import Counter
Counter(weird)

suspect1 = check1[weird] #292 and 390
suspect1.reset_index(inplace=True)

check1.reset_index(inplace=True)

#merge back
full1 = pd.merge(d, check1, on = ['subj','id'])
normal = (full1['median_bhhr']>=50) & (full1['min_bhhr']>0) & (full1['act']!='sync')
normal = (full1['subj'] != '292') & (full1['subj'] !='390')& (full1['act']!='sync')
normal = full1['act']!='sync'
full2 = full1[normal]
full2['logy'] = np.log(np.abs(full2['diff_bh']))
full2.shape

full2.to_csv('full_hr.csv')




################################################################
import statsmodels.api as sm
import statsmodels.formula.api as smf

fam = sm.families.Gaussian()
ind = sm.cov_struct.Autoregressive() #first order
#ind = sm.cov_struct.Exchangeable()

mod = smf.gee("logy ~ act + subj", "id", full2,\
              cov_struct=ind, family=fam)

#can specify weights
#predictor is subject,
#weights is the probability for each cluster
#build GEE for each cluster to see if subj differs

import random
from collections import Counter
cc = Counter(full2['id'])
weight = np.ones(full2.shape[0])
#test different weights
allid = np.unique(full2['id'])
curr = 0
for i in allid:
    tempr = random.random()

    for j in range(0,cc[i]):
        weight[curr+j] = tempr
    curr += cc[i]

mod = smf.gee("logy ~ act + subj", "id", full2,\
              cov_struct=ind, family=fam,weights=weight)

################################################

mod = smf.gee("logy ~ act", "id", full2,\
              cov_struct=ind, family=fam)

res = mod.fit()
print(res.summary())

########################

covmat = res.cov_robust
coef = res.params
np.diag(covmat)

contrast = np.array([1,0,0,0,0,0,0,0,0,0,
                     1,1,0,0,0,0,0,0,0,0,
                     1,0,1,0,0,0,0,0,0,0,
                     1,0,0,1,0,0,0,0,0,0,
                     1,0,0,0,1,0,0,0,0,0,
                     1,0,0,0,0,1,0,0,0,0,
                     1,0,0,0,0,0,1,0,0,0,
                     1,0,0,0,0,0,0,1,0,0,
                     1,0,0,0,0,0,0,0,1,0,
                     1,0,0,0,0,0,0,0,0,1]).reshape(10,10)

meanvar = np.diag(np.dot(np.dot(contrast, covmat),\
                         contrast.T))

#be careful of the order
from scipy.stats import norm
#z = norm.ppf(1 - 0.025)

z = norm.ppf(1 - 0.025/10)

pairwise = pd.DataFrame({'device':coef.index,
              'lower':contrast.dot(coef)-z*np.sqrt(meanvar),
              'upper':contrast.dot(coef)+z*np.sqrt(meanvar)})
pairwise['expmean'] = np.exp(contrast.dot(coef))
pairwise['explower'] = np.exp(pairwise['lower'])
pairwise['expupper'] = np.exp(pairwise['upper'])
pairwise.iloc[:,[0,3,4,5]]

res.fit_history

contrast.dot(coef)
meanvar




#########################################################    
#confusion matrix
import sklearn.metrics as skm

rawmat = skm.confusion_matrix(allcombine.true_label,allcombine.pred_label)
newmat = np.zeros(rawmat.shape)

for i in range(rawmat.shape[0]):
    for j in range(rawmat.shape[1]):
        newmat[i,j] = round(rawmat[i,j]/float(np.sum(rawmat,axis=1)[i]),3)

for i in range(newmat.shape[0]):
    print newmat[i,]

#but this should be subject-specific in the model


grouped = allcombine.groupby(['true_label','pred_label'])
grouped.size()


'''