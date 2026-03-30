#!/usr/bin/env python
# coding: utf-8

# # EXTRAPOLATOR THAT GUESS THE LAST WEEK VALUES BY POLINOMIAL EXTRAPOLATION OF PREVIOUS WEEKS
# ## THE NUMBER OF WEEKS TO BE DISREGRADED ARE DETERMINED BY EXTREME CHANGE IN FIRST DERIVATIVE

# In[1]:


import numpy as np
import pandas as pd
from sklearn.preprocessing import MinMaxScaler
from tensorflow.keras.models import Sequential, load_model
from tensorflow.keras.layers import LSTM, Dense
import matplotlib.pyplot as plt
from sklearn.metrics import mean_squared_error, mean_absolute_error
from scalecast.Forecaster import Forecaster
import time
import os, glob, argparse, sys
import joblib
import re


# In[ ]:


def main():
    # Create an ArgumentParser
    parser = argparse.ArgumentParser(description="Process input arguments")

    # Define command-line arguments for directory and country
    parser.add_argument("--data_directory", type=str, help="Data Directory")
    parser.add_argument("--model_directory", type=str, help="Model Directory")
    parser.add_argument("--country", type=str, help="Country to process")
    
    args = parser.parse_args()

    # Access the directory and country arguments
    directory = args.data_directory
    model = args.model_directory
    country = args.country

    # Redirect stdout to capture the output
    sys.stdout = sys.__stdout__
    
#     print("1. read country ", country)
#     print("1. in directory ", directory)
    
    return directory, model, country

# Call the main function
if __name__ == "__main__":
    # Unpack the tuple returned by main()
    data_dir, model_dir, country = main()
#     print("2. read country ", country)
#     print("2. in directory ", directory)


# ## READ TIME SERIES

# In[2]:


country = str(country).rstrip()
directory = str(data_dir).rstrip()
model = str(model_dir).rstrip()

# print("D: ",directory," M: ",model," C: ",country)

# get the run code to index all subdirectories within (model, training_and_test, predicitons) 
# in the result dir
# Define a regular expression pattern to match the timestamp
pattern = r'\d{2}\.\d{2}\.\d{4}_\d{2}h'
# Use re.search to find the pattern in the input string
match = re.search(pattern, directory)

# Check if a match is found and extract the timestamp
if match:
    data_run_code = match.group()
else:
    print("ERROR: data_run_code not found.")
    sys.exit(1)
    
print("data_run_code ",data_run_code)

# Use re.search to find the pattern in the input string
match = re.search(pattern, model)

# Check if a match is found and extract the timestamp
if match:
    model_run_code = match.group()
else:
    print("ERROR: model_run_code not found.")
    sys.exit(1)
    
print("model_run_code ",model_run_code)

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

# reading time series

# Load epidemiological data (e.g., daily cases)
data = pd.read_csv(filename)
series = data['Smoothed Dengue Cases'].values.reshape(-1, 1)
weeks = data["Date"]

weeks = [week.replace("'", "") for week in weeks] # leio com aspas porque senão le como float
# depois de ler tiro as aspas

# Load the saved MinMaxScaler
scaler = joblib.load(model+'/'+country+'_scaler.pkl')

nweeks = len(weeks)
print("number of epidemiological weeks in dataset: ",nweeks,"\nfirst week is dated at ",\
      weeks[0],"\nlast week is dated at ",weeks[nweeks-1])


# In[ ]:


output_path= '..\\results\\predictions\\DATA_'+data_run_code+'_MODEL_'+model_run_code

if os.path.exists(output_path):
    print(f"output directory {output_path} already exists. files will be rewritten ....")# If it exists, remove it
#     os.rmdir(new_dataset_dir)
else:
    os.makedirs(output_path)
    print(f"created output directory {output_path}")
    


# 
# ## READ A BUNCH OF TRAINED MODELS

# In[3]:


model_path = model

if os.path.exists(model_path):
    print(f"models are read from {model_path}")
else:
    print(f"ERROR: directory {model_path} with models not found ...")
    sys.exit(1)

print("looking for models with the path ",model_path+"/"+country+'*.h5')
model_files = glob.glob(model_path+"/"+country+'*.h5')

# print(model_files)

# Check if any files are found
if not model_files:
    print("ERROR: no model.h5 files found in the directory.")
    sys.exit(1)  # Exit the script with an error code

# files = os.listdir(model_path)
# Filter files that start with the country name and end with .h5
# model_files = [file for file in files if file.startswith(country) and file.endswith('.h5')]
# Now model_files will contain the names of all the files that match the criteria

# print("model file list ",model_files)

nmodels = len(model_files)

if nmodels>0:
    print("loading ",nmodels," trained models for ",country)
    LoadedModel = []
    for file in model_files:
        LoadedModel.append(load_model(file))       
else:
    print("No model file found ...........")
    sys.exit(1)


# In[4]:


input_shape = LoadedModel[0].input_shape
print(input_shape)
history_step = input_shape[1] 
print("history step: ",history_step)
output_shape =  LoadedModel[0].output_shape
print(output_shape)
prediction_interval = output_shape[1] 
print("prediction interval: ",prediction_interval)


# ## EXTRACT THE LAST PART OF THE TIMESERIES TO PERFORM PREDICTION

# In[5]:


# test input data 
if len(weeks)<history_step:
    print('ERROR: timeseries is too short. It must have at least ',len(weeks),' weeks')
    sys.exit(1)
    
input_data =  series[-history_step:][:]
input_weeks = weeks[-history_step:]

ano, lastweek = weeks[-1].split('.')  
semana1 = int(lastweek) + 1  #  primeira semana de predição
semana2 = semana1 + prediction_interval - 1  # última semana desejada

# Use um loop para gerar as strings no formato desejado
output_weeks = [f"{ano}.{semana:02d}" for semana in range(semana1, semana2 + 1)]

tot_weeks = weeks + output_weeks
#     print(tot_weeks)
#     input_data =  series[-history_step-prediction_interval:-prediction_interval][:]
print(input_data)
print(len(input_data)) # input_data é uma matriz porque LSTM requer esse formato
print("input weeks\n",input_weeks)
print("output weeks\n",output_weeks)

input_data0 = input_data.copy()


# ## NEW: CORRECT THE END OF THE INPUT DATA FROM ABNORMAL DISCONTINUITY

# In[6]:


# SAVE ORIGINAL DATA

d = input_data0.flatten().tolist()

# print("input time serie: \n",d)

derivada = np.diff(d)
# print("first derivatives (abs): \n",abs(derivada))
# plt.figure(figsize=(6,3))
# plt.plot(derivada,"k.-")
# plt.ylabel("first derivative of smoothed data")
# plt.xlabel("input week")
# plt.grid()
# plt.title("discontinuity indicator")
# plt.show()

y_min, y_max = plt.ylim()
media = np.mean(abs(derivada))
std = np.std(abs(derivada))
cut_off = media+2*std

# plt.figure(figsize=(6,3))
# plt.hist(abs(derivada),40)
# plt.grid()
# plt.xlabel("first derivative of smoothed data")
# plt.ylabel("frequency")
# plt.title(f"mean {media:.2f} std {std:.2f} cut-off (meam+2*std) = {cut_off:.2f}")
# plt.plot([media+2*std,media+2*std],[y_min,y_max],"r--")
# plt.show()

nova_serie = d

if np.max(abs(derivada)) > cut_off:
    
    recuo = 5 # number of points to build the polynom to be extrapolated 
    degree = 2
    
    if history_step < recuo + 3:
        recuo = history_step - 3

    cut=0
    for i in range(len(derivada)):
        if abs(derivada[i])>cut_off:
            cut = i+1
            break

    # correcting the end of the series
    if cut >= recuo:
    
        print("first week to cut = ",cut)
        
        x = np.arange(cut-recuo,cut)
        y = d[cut-recuo:cut]

        # Ajustar uma parábola aos pontos (regressão quadrática)
        coeffs = np.polyfit(x, y, degree)  # Grau 2 para parábola

        # Coeficientes da parábola (a*x^2 + b*x + c)
        a, b, c = coeffs

        # Gerar novos valores de x (xhat)
        n = max(x)
        m = len(d)-cut  # Número de valores adicionais de x
        xhat = np.arange(n + 1, n + m + 1)

        # Calcular os valores correspondentes de yhat
        yhat = a * xhat ** 2 + b * xhat + c

        yhat[yhat < 0] = 0

        xhat=xhat.tolist()
        yhat=yhat.tolist()

        n_modified = len(yhat)
        nova_serie = list(d[:cut])+yhat
        # # Plotar x vs y
        # plt.plot(x, y, 'o', label='Dados Originais')
        # plt.xlabel('x')
        # plt.ylabel('y')

        # # Plotar xhat vs yhat
        # plt.plot(xhat, yhat, 's', label='Dados Estimados (yhat)')
        # plt.legend()
        # plt.title('Ajuste de Parábola e Valores Estimados')
        # plt.show()

        print("number of past points for regression: ",recuo)
        print("regression polynom degree: ",degree)

        x = list(np.arange(cut))+xhat
        # Defina os índices dos ticks que deseja rotular, espaçados a cada 10 valores
        input_ticks = range(nweeks-len(x), nweeks, 1)
        # Associe os rótulos aos índices de ticks
        rotulos_input_ticks = [weeks[i] for i in input_ticks]
        # plt.figure(figsize=(6,3))
        fig, ax = plt.subplots(figsize=(10,7))
        plt.plot(input_ticks[:cut],d[:cut],"gd-",label="kept data")
        plt.plot(input_ticks[cut:],d[cut:],"r.-",label="to modify data")
        plt.plot(input_ticks[cut:],yhat,"yd-",label="modified data")
        plt.plot(input_ticks,nova_serie,"k.:",label="rebuilt input data")
        ax.set_xticks(input_ticks)
        ax.set_xticklabels(rotulos_input_ticks, rotation=45)
        plt.ylabel("cases")
        plt.xlabel("input weeks")
        plt.legend()
        plt.grid()
        plt.title("input time series")
        plt.savefig(output_path+"/"+country+"_input_data_modifications.jpeg", format='jpeg', dpi=300)
        plt.close()

input_data = np.array(nova_serie).reshape(-1, 1)
input_data


# ## SCALE DOWN INPUT DATA

# In[7]:


scaled_input_data = scaler.transform(input_data)
print(scaled_input_data)


# ## REFORMAT INPUT DATA FOR THE LSTM NETWORK INPUT FORMAT

# In[8]:


scaled_input_data = np.expand_dims(scaled_input_data, axis=0)
print(scaled_input_data)
print(np.array(scaled_input_data).shape)


# ## RUN ALL THE MODELS FOR PREDICTING ALL WEEKS FORWARD AND PLOT THE RESULTS AFTER BACK-SCALING

# In[9]:


toplt=False

if toplt:
    plt.figure(figsize=(prediction_interval,3))
ctr=1
Predictions=[]
for model in LoadedModel:
    ctr+=1
    scaled_predictions = model.predict(scaled_input_data,verbose=0) # PREDICTING
    scaled_predictions[scaled_predictions < 0] = 0 # CORRECT NEGATIVE VALUES
    predictions = scaler.inverse_transform(scaled_predictions) # BACK-SCALING
    Predictions.append(predictions[0][:])
    if toplt:
        plt.plot(predictions[0][:],'k.')
# for w in range(len(predictions[0])):
#     plt.plot(w,np.mean(Predictions, axis=0),'rd')
if toplt:
    plt.grid()
    plt.show()


# In[10]:


mean_prediction = np.mean(Predictions, axis=0)
std_prediction = np.std(Predictions, axis=0)
print(np.array(Predictions).shape)
print(mean_prediction)
print(std_prediction)
pred_max = np.max(mean_prediction + 2*std_prediction)
upper_bound = mean_prediction + 2*std_prediction
lower_bound = mean_prediction - 2*std_prediction
lower_bound[lower_bound<0]=0

# plt.figure(figsize=(prediction_interval+history_step,5))
# plt.plot(input_data,"b.-")
# plt.fill_between(history_step+np.arange(prediction_interval), lower_bound, \
#                      upper_bound, color='gray', \
#                      alpha=0.5, label='+2/-2 standard deviation')
# plt.plot(history_step+np.arange(prediction_interval),mean_prediction,"k.-")
# plt.ylim([0,1.05*np.max([pred_max,np.max(input_data)])])
# plt.grid()
# plt.xlabel("epidemiological week",fontsize=12)
# plt.ylabel("weekly Dengue cases",fontsize=12)
# plt.title("INPUT TIME SERIES AND PREDICTED VALUES WITH $\pm$ STANDARD DEVIATION")
# plt.show()


# In[13]:


# definindo quantos dadso do passado para conmtectualizar serão plotados
prev_data = history_step
prev_series = series[-history_step-prev_data:-history_step]
prev_max = np.max(prev_series)

mean_prediction = np.mean(Predictions, axis=0)
std_prediction = np.std(Predictions, axis=0)
print(np.array(Predictions).shape)
print(mean_prediction)
print(std_prediction)
pred_max = np.max(mean_prediction + 2*std_prediction)

upper_bound = mean_prediction + 2*std_prediction
lower_bound = mean_prediction - 2*std_prediction
lower_bound[lower_bound<0]=0

data_max = np.max(input_data)
orig_data_max = 0 #np.max(original_input_data)

x_input = np.arange(nweeks - history_step, nweeks)
if len(x_input)!=history_step:
    print("ERRO x_input")
x_prev = np.arange(nweeks - history_step - prev_data, nweeks - history_step)
if len(x_prev)!=len(prev_series):
    print("ERRO x_prev")

x_pred = np.arange(nweeks, nweeks + prediction_interval )
predicted_weeks =  output_weeks

x_tot =list(x_prev)+list(x_input)+list(x_pred)
weeks2plot = [tot_weeks[i] for i in x_tot]

fig, ax = plt.subplots(figsize=(16,8))
plt.plot(x_prev,prev_series,"r.-",label="previous not used data")
plt.plot(x_input,input_data,"b.-",label="used input data")
plt.fill_between(x_pred, lower_bound, \
                     upper_bound, color='gray', \
                     alpha=0.5, label="range $\pm 2$ stdev")
plt.plot(x_pred,mean_prediction,"k.-",label = 'mean prediction')
ax.set_xticks(x_tot)
ax.set_xticklabels(weeks2plot, rotation=45)
plt.ylim([0,1.05*np.max([pred_max,data_max,orig_data_max,prev_max])])
plt.grid()
plt.legend()
plt.xlabel("epidemiological week",fontsize=12)
plt.ylabel("weekly Dengue cases",fontsize=12)
plt.title(country+": average predicted weekly rate: {:.1f}".format(np.mean(np.diff(mean_prediction)))+\
          " cases/week",fontsize=14)
plt.savefig(output_path+"/"+country+"_4weeks_prediction_since_week_"+tot_weeks[-prediction_interval]+\
            "-"+tot_weeks[-1]+".jpeg", format='jpeg', dpi=300)
# plt.savefig(country+"_NEW_4weeks_prediction_since_week_"+tot_weeks[-prediction_interval]+\
#             "-"+tot_weeks[-1]+".png")
plt.close()

# Crie um dicionário com os arrays
pred = {
    'Upper_Bound': upper_bound,
    'Lower_Bound': lower_bound,
    'Mean_Prediction': mean_prediction
}

# Crie um DataFrame com o dicionário de dados
pr = pd.DataFrame(pred)

# Salve o DataFrame em um arquivo CSV
pr.to_csv(output_path+'/'+country+'_dengue_pred_4plusweeks.csv', index=False) 


# In[ ]:


# predicted weekly rate 
print("average weekly rate in the predicted interval: ",np.mean(np.diff(mean_prediction))," cases/week")

