# Defining the signal quality of heart rate data

## Part 1: reliability of Bioharness heart rate 

In this part, we want to evaluate the reliability of Biorharness heart rate in different cluster
states for each subject, assuming the concurrent Shimmer heart rate to be the ground truth. The
signal reliability is negatively correlated with the log absolute error versus the ground truth.

First, follow **reliability_process.py** to preprocess the raw data in the NCSU-ADL folder, which contains
both the raw data with activity label and learned data (from some unsupervised model) with cluster 
states. This will output **reliability.csv**, which will be the analysis data set. Next, follow 
**reliability_clean.sas** to compute the confidence interval for the mean absolute error
using the generalized estimating equations method (Liang and Zeger, 1986) and its weighted 
extension (Robins and Rotnitzky, 1995).

## Part 2: anomaly detection by peak-to-peak interval

In this part, we assume that there is no ground truth available. Thus, we are comparing the heart rate signal 
quality based on the anomaly detection using common thresholding algorithms. A good signal should have a low 
number of anomalies per unit of time. 

First, follow **anomaly_process.py** to preprocess the anomaly data in the ADLData-HR-Anomaly folder, which 
will produce the **anomaly.csv** analysis data. 
Then, follow **anomaly_clean.sas** to compute the confidence interval for the mean number of anomalies per
minute for each subject-specific activity via Poisson regression by setting the log duration as offset.


