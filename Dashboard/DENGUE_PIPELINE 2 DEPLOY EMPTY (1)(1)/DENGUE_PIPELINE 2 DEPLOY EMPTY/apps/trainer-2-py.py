#!/usr/bin/env python
# coding: utf-8

# In[2]:


import numpy as np
import pandas as pd
from sklearn.preprocessing import MinMaxScaler
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense
import matplotlib.pyplot as plt
from sklearn.metrics import mean_squared_error, mean_absolute_error
import time
import joblib# Import necessary libraries
import argparse
import sys, os, glob
import statsmodels.api as sm
from unidecode import unidecode as decode
import re


# # THIS VERSION RECEIVES THE DATA DIRECTORY AND THE COUNTRY NAME FROM A BASH SCRIPT

# In[3]:


def main():
    # Create an ArgumentParser
    parser = argparse.ArgumentParser(description="Process input arguments")

    # Define command-line arguments for directory and country
    parser.add_argument("--directory", type=str, help="Directory of countries")
    parser.add_argument("--country", type=str, help="Country to process")
    
    args = parser.parse_args()

    # Access the directory and country arguments
    directory = args.directory
    country = args.country

    # Redirect stdout to capture the output
    sys.stdout = sys.__stdout__
    
#     print("1. read country ", country)
#     print("1. in directory ", directory)
    
    return directory, country

# Call the main function
if __name__ == "__main__":
    # Unpack the tuple returned by main()
    directory, country = main()
#     print("2. read country ", country)
#     print("2. in directory ", directory)


# ## reading and splitting time series

# In[ ]:


# reading time series

country = str(country).rstrip()
directory = str(directory).rstrip()

# get the run code to index all subdirectories within (model, training_and_test, predicitons) 
# in the result dir
# Define a regular expression pattern to match the timestamp
pattern = r'\d{2}\.\d{2}\.\d{4}_\d{2}h'
# Use re.search to find the pattern in the input string
match = re.search(pattern, directory)

# Check if a match is found and extract the timestamp
if match:
    run_code = match.group()
else:
    print("ERROR: run_code not found.")
    sys.exit(1)
    
print("run_code ",run_code)

substr = "_*.csv"
file2search = directory+"\\"+country+substr
all_files = glob.glob(file2search)

# Check if any files are found
if not all_files:
    print("ERROR: no csv file found in the directory.")
    sys.exit(1)  # Exit the script with an error code

# Choose the first file as the variable part of the filename
if len(all_files)>1:
    print("ERROR: multiple .csv files found in the directory.")
    sys.exit(1)  # Exit the script with an error code
    
filename = all_files[0].replace('/','\\')
print(f'file found {filename}')

# Load epidemiological data (cases timeseries)

data = pd.read_csv(filename)
    
series = data['Smoothed Dengue Cases'].values.reshape(-1, 1)

output_path_training_test = '..\\results\\training_and_test\\'+run_code

if os.path.exists(output_path_training_test):
    print(f"output directory {output_path_training_test} already exists. files will be rewritten ....")# If it exists, remove it
#     os.rmdir(new_dataset_dir)
else:
    os.makedirs(output_path_training_test)
    print(f"created output directory {output_path_training_test}")
    
output_path_model = '..\\results\\models\\'+run_code

if os.path.exists(output_path_model):
    print(f"output directory {output_path_model} already exists. files will be rewritten ....")# If it exists, remove it
#     os.rmdir(new_dataset_dir)
else:
    os.makedirs(output_path_model)
    print(f"created output directory {output_path_model}")
    
# Normalize the data to a range between 0 and 1
scaler = MinMaxScaler()
series = scaler.fit_transform(series)

# Save the scaler to the model directory
joblib.dump(scaler, output_path_model+'\\'+country+'_scaler.pkl')

# Split the data into training and test sets
train_size = int(len(series) * 0.7)
test_size = len(series) - train_size
train_data, test_data = series[0:train_size,:], series[train_size:len(series),:]

df_train = data[:train_size].reset_index()
df_test =  data[train_size:].reset_index()

# time interval for training plot
train_weeks = df_train["Date"]

plt.figure(figsize=(10, 4))
plt.plot(df_train["Smoothed Dengue Cases"],"r.-")
tick_pos = np.arange(0,len(df_train),10)
plt.xticks(tick_pos, np.array(train_weeks)[tick_pos], rotation=90)  # Set text labels and proper
plt.grid()
plt.xlabel("epidemic week")
plt.ylabel("dengue weekly cases")
plt.title("time series interval for TRAINING at "+country)
plt.savefig(output_path_training_test+'\\'+country+'_training_series.jpg', format='jpeg', dpi=300, bbox_inches='tight')
plt.close()
# time interval for test plot
test_weeks = df_test["Date"]

plt.figure(figsize=(10, 4))
plt.plot(df_test["Smoothed Dengue Cases"],"b.-")
tick_pos = np.arange(0,len(df_test),5)
plt.xticks(tick_pos, np.array(test_weeks)[tick_pos], rotation=90)  # Set text labels and proper
plt.grid()
plt.xlabel("epidemic week")
plt.ylabel("dengue weekly cases")
plt.title("time series interval for TESTING at "+country)
plt.savefig(output_path_training_test+'\\'+country+'_test_series.jpg', format='jpeg', dpi=300, bbox_inches='tight')
plt.close()

print(f"saved training and test timeseries for country {country}")


# In[3]:


# df_test


# In[4]:


# Create sequences for training and test
def create_sequences(data, history_step, forward_step, prediction_interval):
    sequences, targets = [], []
    for i in range(len(data) - history_step - prediction_interval - forward_step + 2):
        j = i + history_step # onde termina a janela backward 
        sequence = data[i : j] # janela backward
        k = j + forward_step - 1 # onde começa a predição depois do salto
        target = data[k : k + prediction_interval] # janela do target 
        sequences.append(sequence)
        targets.append(target)
    return np.array(sequences), np.array(targets), k


# In[5]:


# splitting time-series

forward_step = 1
prediction_interval = 4 # 4
fact = int( 1 + prediction_interval / 2 )
history_step = 8 + 2 * fact # 10

# last_train_target_init_point = ltrain
# last_test_target_init_point = ltrain

X_train, y_train, ltrain = create_sequences(train_data, history_step, forward_step, prediction_interval)
X_test, y_test, ltest = create_sequences(test_data, history_step, forward_step, prediction_interval)

print("training data shape> input: ",X_train.shape," output: ",y_train.shape,\
      " training interval: [",\
     df_train["Date"][0],",",df_train["Date"][ltrain+prediction_interval-1],"]")
print("test data shape> input: ",X_test.shape," output: ",y_test.shape,\
      " test interval: [", \
      df_test["Date"][0],",",df_test["Date"][ltest+prediction_interval-1],"]")

# print(f"training and test timeseries were split")


# In[9]:


# Build the LSTM model
Model=[]
Predictions = []
nruns = 50
epochs_by_fact = 25

tic=time.time()
for run in range(nruns):
    
    print(f"model {run}/{nruns} is being trained")
    model = Sequential()
    model.add(LSTM(fact * 120, activation='relu', input_shape=(history_step,1))) # era 80
    model.add(Dense(prediction_interval))
    model.compile(optimizer='adam', loss='mean_squared_error')

    # Train the model
    history = model.fit(X_train, y_train, epochs = fact * epochs_by_fact, \
                        batch_size = fact * 8, validation_split = 0.1, verbose=0) # era 8
    Model.append(model)
    model.save(output_path_model+'\\'+country+'_model_'+str(run)+".h5")
    
    # Visualize training and validation loss
    plt.figure(figsize=(4,1))
    plt.plot(history.history['loss'], label='Training Loss')
    plt.plot(history.history['val_loss'], label='Validation Loss')
    plt.xlabel('Epochs')
    plt.ylabel('Loss')
    plt.title('Training and Validation Loss @ Run '+str(run+1))
    plt.legend()
    plt.savefig(output_path_training_test+'\\'+country+'_loss_of_model'+str(run+1)+'.jpg', format='jpeg', dpi=300, bbox_inches='tight')
    plt.close()

    print(f"loss saved ....")
    # Make predictions on test data

#     print("X_test shape ",X_test.shape)
    predictions = model.predict(X_test,verbose=0)
#     print("predictions shape ",predictions.shape)

    # Reshape y_test to a 2-dimensional array
    Y_test = y_test.reshape(-1,prediction_interval)
#     print("Y_test shape ",Y_test.shape)

    # Desnormalize the predictions and targets
    predictions = scaler.inverse_transform(predictions)
    Y_test = scaler.inverse_transform(Y_test)

    Predictions.append(predictions)
    # Calculate appropriate performance metrics for time series prediction

#     mse = mean_squared_error(Y_test, predictions)
#     mae = mean_absolute_error(Y_test, predictions)
#     rmse = np.sqrt(mse)

#     print(f"Mean Squared Error (MSE): {mse}")
#     print(f"Mean Absolute Error (MAE): {mae}")
#     print(f"Root Mean Squared Error (RMSE): {rmse}")

print("time per run ", ((time.time()-tic)/60/nruns)," minutes")
print("total time with ",nruns," runs : ",(time.time()-tic)/60," minutes")


# In[10]:


# # Plot the original and predicted time series data
# test_n = len(Y_test)
# tick_pos = np.arange(0,test_n,5)
# nruns2plot = 5
# for i in range(prediction_interval): # loop for prediction_interval
#     plt.figure(figsize=(10, 3))
#     plt.plot(np.arange(test_n),Y_test[:,i], label='Original Data', marker='.')
#     plt.xticks(tick_pos, np.array(test_weeks)[tick_pos], rotation=90)  # Set text labels and properties.
#     for run in range(nruns2plot):
#         plt.plot(np.array(Predictions)[run,:,i], label='Prediction @ week +'+str(i+1+forward_step-1)+' run '+str(run+1))
#     plt.xlabel('Date (epidiological weeks)')
#     plt.ylabel('Dengue Cases')
#     plt.title('Original (TEST) and Predicted Time Series Data for '+country)
#     # plt.ylim([0,1.05*np.max([predictions,Y_test])])
#     plt.legend()
#     plt.grid()
#     plt.show()

# # Mpred = np.max(predictions)


# In[11]:


# Calculation of ensemble mean and standard deviation for each forecasted week ahead

toplt1=False
mean_prediction = np.mean(Predictions,axis=0)
prediction_std = np.std(Predictions, axis=0)

num_test_cases = np.sum(df_test["Dengue Cases"])/len(df_test)
# print(mean_prediction.shape,prediction_std.shape)

# plot distribuiton of std
for i in range(prediction_interval):
    if toplt1:
        plt.figure(figsize=(3,2))
        plt.hist(prediction_std[:,i],30,label="week+"+str(i+1))
        print("mean standard deviation for week+"+str(i+1)+" predicted values = ",\
              np.mean(prediction_std[:,i]))
        plt.title("mean standard deviation= {:.0f}".format(np.mean(prediction_std[:,i]))+" cases"\
                  "\naverage # weekly cases in the test period= {:.0f}".format(num_test_cases),fontsize=8)
        plt.grid()
        plt.xlim([0,np.max(prediction_std)])
        plt.xlabel("week-wise standard deviation")
        plt.ylabel('frequency')
        plt.legend()
        plt.show()


# In[12]:


# Plot the original and predicted time series data
test_n = len(Y_test)
tick_pos = np.arange(0,test_n,5)
for i in range(prediction_interval): # loop for prediction_interval
    print(f"showing predictions in the test interval for week+{i+1}")
    plt.figure(figsize=(10, 3))
    plt.plot(np.arange(test_n),Y_test[:,i], label='Original Data', marker='.')
    plt.xticks(tick_pos, np.array(test_weeks)[tick_pos], rotation=90)  # Set text labels and properties.
    # Plot the mean value as a horizontal line
    plt.plot(mean_prediction[:,i], label='Mean', color='r', linestyle='--', linewidth=1)
    # Shade the area representing the variance
    plt.fill_between(np.arange(test_n), mean_prediction[:,i] - 2*prediction_std[:,i], \
                     mean_prediction[:,i] + 2*prediction_std[:,i], color='gray', \
                     alpha=0.5, label='+2/-2 standard deviation')
#     plt.plot(np.array(Predictions)[run,:,i], label='Prediction @ week +'+str(i+1+forward_step-1)+' run '+str(run+1))
    plt.xlabel('Date (epidiological weeks)')
    plt.ylabel('Dengue Cases')
    plt.title('Original (TEST) and Predicted Confidence Interval for '+country+\
              ' @ week +'+str(i+1+forward_step-1)+'\n2 Mean Standard Deviation: '+str(2*np.mean(prediction_std[:,i])))
    # plt.ylim([0,1.05*np.max([predictions,Y_test])])
    plt.legend()
    plt.grid()
    plt.savefig(output_path_training_test+'\\'+country+'_test_result_grayzone_week'+str(i+1+forward_step-1)+'.jpg', format='jpeg', dpi=300, bbox_inches='tight')
    print("prediction on test interval saved ...")
    plt.close()


# In[13]:


def rel_mape(actual_values, predicted_values, window_size):
    
    window_size += 1
    idx_nonzero = np.nonzero(actual_values)
    actual_nonzero = actual_values[idx_nonzero]
    predicted_nonzero = predicted_values[idx_nonzero]
    n = len(actual_nonzero)
    nw = n // window_size
    
    mape_values = []
    
    for i in range(1,nw+1):
        window_actual = actual_nonzero[(i-1)*window_size:i*window_size]
        window_predicted = predicted_nonzero[(i-1)*window_size:i*window_size]
        actual_mean = np.mean(window_actual) # local mean
        # mape relative to the mean actual values on the window
        local_mape = np.mean(np.abs(window_actual - window_predicted) / actual_mean) 
        mape_values.append(local_mape)
    
    return np.mean(100*np.array(mape_values)), np.std(100*np.array(mape_values))


# In[15]:


window_size = prediction_interval # history_step

for i in range(prediction_interval):
    print(f"showing correlation of predicted vs real data in the test interval for week+{i+1}")
    mean_mape, std_mape = rel_mape(Y_test[:,i], mean_prediction[:,i], 2*window_size)
#     print(mape_values)
    plt.plot(Y_test[:,i],mean_prediction[:,i],'k.')
    plt.xlabel("ground truth")
    plt.ylabel("prediction")
    plt.title("predicting "+str(i+1)+" week(s) ahead, \naverage MAPE= {:.2f}".format(mean_mape)+" %")#+\
#              "stdev = {:.2f}".format(std_mape)+" %")
    plt.grid()
    plt.savefig(output_path_training_test+'\\'+country+'_pred_data_correlation_week'+str(i+1+forward_step-1)+'.jpg', format='jpeg', dpi=300, bbox_inches='tight')
    print("correlation saved ...")
    plt.close()


# In[16]:


# gray zone definition

for i in range(prediction_interval):
    
    print(f"showing lower and upper bounds in test interval for week+{i+1}")
    # Sample original time series
    original_series = Y_test[:,i]

    # Sample predicted time series
    predicted_series = mean_prediction[:,i]
    X = sm.add_constant(predicted_series)

    # Fit a linear regression model to the original series
    linmodel = sm.OLS(original_series,X).fit()

    # Calculate the prediction intervals for the predicted series
    alpha = 0.05
    prediction_intervals = linmodel.get_prediction(X).summary_frame(alpha=alpha)

    # Extract lower and upper bounds of the prediction intervals
    lower_bound = prediction_intervals['obs_ci_lower']
    upper_bound = prediction_intervals['obs_ci_upper']

    # Create a DataFrame to store the results
    confidence_intervals = pd.DataFrame({
        'Original': original_series,
        'Predicted': predicted_series,
        'Lower Bound': lower_bound,
        'Upper Bound': upper_bound
    })
    plt.figure(figsize=(10, 3))
    plt.plot(np.arange(test_n),original_series,"k.",label="original series")
#     plt.plot(predicted_series,"m.-",label="predicted series")
    plt.plot(np.arange(test_n),lower_bound,"r--",label="lower bound")
    plt.plot(np.arange(test_n),upper_bound,"b--",label="upper bound")
    plt.xticks(tick_pos, np.array(test_weeks)[tick_pos], rotation=90)  # S
    plt.legend()
    plt.xlabel("test weeks")
    plt.ylabel("weekly Dengue cases")
    plt.title('Original and Predicted Data for '+country+' @ week +'+str(i+1+forward_step-1)+\
              '\nLower and Upper Bounds with {:.2f}'.format(1-alpha)+' Confidence Interval')
    plt.grid()
    plt.savefig(output_path_training_test+'\\'+country+'_test_result_low_and_upper_bounds_week'+str(i+1+forward_step-1)+'.jpg', format='jpeg', dpi=300, bbox_inches='tight')
    print(f"saving figure to file")
    plt.close()

#     print(confidence_intervals)


# In[ ]:




