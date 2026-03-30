#!/usr/bin/env python
# coding: utf-8

# In[14]:


import numpy as np
# from matplotlib import pyplot as plt
import pandas as pd
from sklearn.metrics import mean_squared_error as MSE
from unidecode import unidecode as decode
from datetime import datetime
import os, shutil, sys
from matplotlib import pyplot as plt
import argparse


# In[ ]:


# Define the main section
def main():
    
     # Create an ArgumentParser
    parser = argparse.ArgumentParser(description="Process input arguments")

    # Define command-line arguments for directory and country
    parser.add_argument("--directory", type=str, help="Directory of data")
    parser.add_argument("--file", type=str, help="Dataset name")
    
    args = parser.parse_args()

    # Access the directory and country arguments
    directory = str(args.directory).rstrip()
    file = str(args.file).rstrip()
    
    print(directory,file)

    # Redirect stdout to capture the output
    sys.stdout = sys.__stdout__
    
    return directory, file
    
# Call the main function
if __name__ == "__main__":
    data_directory, input_file  = main()


# In[3]:


# Get the current working directory
# current_directory = os.getcwd()

# local_dir = current_directory.split("\\")[-1]

# if local_dir!='apps':
#     sys.exit("RUNNING PREPROCESSOR APP FROM A WRONG DIRECTORY\nIT MUST BE RUN FROM APPS DIRECTORY WITHIN THE BASE DIRECTORY...")

# observation: RUNNING PIPELINE FRoM COMMNAD LINE THIS FILE NAME CAME AS ARGUMENT
# input_file_name = file.split('.cs')[0]
# #'new_new_selected_dengue_data_utf8' 
# input_file = input_file_name+'.csv' 

# directory_contents = os.listdir(data_directory)
# # Print the contents
# print("Contents of the directory:",data_directory)
# for item in directory_contents:
#     print(item)
    
# THE SCRIPT MUST BE RUNNING FROM THE APP DIRECTORY => THEN WE SET WHERE IT MUST READ DATA ../data
# data_directory = os.path.join(current_directory, f'../data') 
# print("data read from ",data_directory)

# print("Expected Data Directory:", data_directory, " Input Directory:", directory)

input_file_path = os.path.join(data_directory, input_file)
print("reading time series from ",input_file_path)

data =  pd.read_csv(input_file_path, sep = ",", low_memory = False, parse_dates = True) 
data = data.fillna(0)


# In[4]:


weeks = list(data.columns[1:])
nweeks = len(weeks)
# Corrija a interpretação das semanas no formato "ano.semana"
for i in range(nweeks):
    if "." in weeks[i]:
        ano, semana = weeks[i].split('.')
        ano = int(ano)
        semana = int(semana)+1 # TIVE QUE SOMAR +1 PARA BATER COM A REALIDADE DO ARQUIVO
        weeks[i] = f"{ano:04d}.{semana:02d}"
    else:
        weeks[i] = f"{weeks[i]}.{1:02d}"
# weeks = data.columns.apply(converter_semana, axis=1)

print("read ",nweeks," weeks:\n",weeks)

# just to plot lines dividing the years later

year_lims=[]

for i in range(nweeks):
    if weeks[i].find(".01")>0:
        year_lims.append(i)    
# print(year_lims)

x = np.arange(nweeks)
# Defina os índices dos ticks que deseja rotular, espaçados a cada 10 valores
indices_ticks = range(0, len(x), 15)
# Associe os rótulos aos índices de ticks
rotulos_ticks = [weeks[i] for i in indices_ticks]


# In[12]:


traducoes_paises = {
    'Anguila': 'Anguilla',
    'Antigua y Barbuda': 'Antigua and Barbuda',
    'Argentina': 'Argentina',
    'Aruba': 'Aruba',
    'Bahamas': 'Bahamas',
    'Barbados': 'Barbados',
    'Belice': 'Belice',
    'Bermuda': 'Bermuda',
    'Bolivia': 'Bolivia',
    'Bonaire San Eustaquio y Saba': 'Bonaire, Sint Eustatius and Saba',
    'Brasil': 'Brazil',
    'Canadá': 'Canada',
    'Chile': 'Chile',
    'Colombia': 'Colombia',
    'Costa Rica': 'Costa Rica',
    'Cuba': 'Cuba',
    'Curazao': 'Curaçao',
    'Dominica': 'Dominica',
    'Ecuador': 'Ecuador',
    'El Salvador': 'El Salvador',
    'Estados Unidos de América': 'United States of America',
    'Granada': 'Grenada',
    'Guadalupe': 'Guadeloupe',
    'Guatemala': 'Guatemala',
    'Guayana Francesa': 'French Guiana',
    'Guyana': 'Guyana',
    'Haití': 'Haiti',
    'Honduras': 'Honduras',
    'Isla de San Martín (Francia)': 'Saint Martin (French part)',
    'Isla de San Martín (Holanda)': 'Sint Maarten (Dutch part)',
    'Islas Caimán': 'Cayman Islands',
    'Islas Turcas y Caicos': 'Turks and Caicos Islands',
    'Islas Vírgenes (EUA)': 'Virgin Islands (U.S.)',
    'Islas Vírgenes (RU)': 'Virgin Islands (British)',
    'Jamaica': 'Jamaica',
    'Martinica': 'Martinique',
    'México': 'Mexico',
    'Montserrat': 'Montserrat',
    'Nicaragua': 'Nicaragua',
    'Panamá': 'Panama',
    'Paraguay': 'Paraguay',
    'Perú': 'Peru',
    'Puerto Rico': 'Puerto Rico',
    'República Dominicana': 'Dominican Republic',
    'Saint Kitts y Nevis': 'Saint Kitts and Nevis',
    'San Bartolomé': 'Saint Barthélemy',
    'San Vicente y las Granadinas': 'Saint Vincent and the Grenadines',
    'Santa Lucía': 'Saint Lucia',
    'Suriname': 'Suriname',
    'Trinidad y Tobago': 'Trinidad and Tobago',
    'Uruguay': 'Uruguay',
    'Venezuela': 'Venezuela'
}

countries = list(data.iloc[:,0].reset_index(drop=True)[1:]) # a primeira linha 0 é o numeral dos paises

ctr=0
for country in countries:
    countries[ctr] = decode(country)
    ctr+=1

    nctry = len(countries)

# Use o dicionário 'traducoes_paises' para traduzir a lista
countries = [traducoes_paises.get(pais, pais) for pais in countries]

print(f"processing data from {nctry} countries:\n",countries)



# In[10]:


timestamp = datetime.now().strftime("%d.%m.%Y_%Hh")

# Combine the country name and timestamp for the file name
new_dir = f"{timestamp}_training_data/"

# Create the subdirectory in the current working directory
new_dataset_dir = os.path.join(data_directory, new_dir)
# Check if the directory already exists
if os.path.exists(new_dataset_dir):
    print(f"output directory {new_dataset_dir} already exists. files will be rewritten ....")# If it exists, remove it
#     os.rmdir(new_dataset_dir)
else:
    os.makedirs(new_dataset_dir)
    print(f"created output directory {new_dataset_dir}")

# Use shutil.copy to copy the file to the destination directory

new_file_name = f'Original_Data_From_File_{input_file}' 

# Use os.path.join to create the new destination path
new_destination_path = os.path.join(new_dataset_dir, new_file_name)

shutil.copy(input_file_path, new_destination_path)

# Define the file path where you want to save the list
country_list_file_path = new_dataset_dir+"/country_list.txt"

# Open the file in write mode
with open(country_list_file_path, "w") as file:
    # Write each country name to the file, one per line
    for country in countries:
        file.write(country + "\n")


# In[15]:


cases=[]
toplt = False

for i in range(nctry):
    cases.append(list(data.iloc[i+1,:].reset_index(drop=True)[1:]))
    if toplt:
        plt.figure(figsize=(14,3))
        plt.plot(cases[i])
        plt.title(countries[i])
        plt.grid()
        plt.show()
        plt.close()

if nweeks != len(cases[0]):
    print("there are more weeks in the dataset-head than in the timeseries.....")
    


# In[6]:


def polyend(degree, npoints, y_in): # Define the degree of the polynomial

    x = np.arange(npoints)
    y = y_in[-npoints:]
    
    # Fit the polynomial using numpy's polyfit function
    coefficients = np.polyfit(x, y, degree)
    
    # Print the coefficients
    print("Coefficients:", coefficients)
    
    # Create a polynomial function using the coefficients
    poly_function = np.poly1d(coefficients)
    print(poly_function)
    
    # Calculate corresponding y values using the polynomial function
    y_fit = poly_function(x)

    shift = y_in[-npoints]-y_fit[0]
    # print("y_input[-npoints] ",y_in[-npoints]," y_fit[0] ",y_fit[0], " shift ",shift)

    return np.array(y_fit+shift)
    


# In[7]:


def diego_smooth(data : pd.DataFrame, n : int, w : int, niter : int, rescale : int, fweight : float, fitend : bool) -> pd.DataFrame:
    
    df_smooth = data.copy()[0:n]
    ndf_smooth = df_smooth.copy()
    
    M = 0.9*np.max(list(df_smooth))
    m = 1.1*np.min(list(df_smooth))
    
    for iter in range(niter): # iterações de suavizamento
        
        df_smooth = ndf_smooth.copy()
        
        # suavizamento por média móvel em janela simétrica de tamanho 2w+1
        
        for d in range(w+1): # inicio do intervalo temporal
            ndf_smooth[d]=np.mean(df_smooth[:d+w])  
            
        for d in range(w+1,n-w): # seção principal do intervalo temporal
            ndf_smooth[d]=np.mean(df_smooth[d-w:d+w]) 
            
        for d in range(n-w,n): # fim do intervalo temporal
            ndf_smooth[d]= fweight*df_smooth[d] + (1-fweight)*np.mean(df_smooth[d-w:n])       
    
        # rescaling 
        sM =  0.9*np.max(list(ndf_smooth))
        sm =  1.1*np.min(list(ndf_smooth))
        
    if rescale ==0:
        toreturn = np.array(ndf_smooth) #(m+(np.array(ndf_smooth)-sm)*(M-m)/(sM-sm)
    else:
        toreturn = np.array(m+(np.array(ndf_smooth)-sm)*(M-m)/(sM-sm))

    if fitend:
        
        npoints = 6
        degree = 2
        
        # series_end = polyend(degree, npoints, data)
    
        series_end = polyend(degree, npoints, toreturn)
    
        # print("y_input ",toreturn[-npoints:],"\nend ",series_end)
    
        toreturn = np.array(list(toreturn)[:-npoints]+list(series_end))
    
    return toreturn
    


# In[19]:


#  3S method
# PARÂMETROS DO MÉTODO DE SUAVIZAMENTO
w = 4 # 6 semi window size
niter = 2 # 4 number of iterations

smooth_by_ctry = []

for p in range(nctry):
    print("smoothing series ",countries[p])
    inp_serie= cases[p].copy()
#     print(len(inp_serie),"\n",inp_serie)
#     print("inp serie len ",len(inp_serie))
    inp_sz = len(inp_serie)
    if inp_sz>=4*w:
        out_serie=diego_smooth(inp_serie, inp_sz, w, niter, 0, 0.6,False) # the before last prm rescale = 0 (not) or 1 (yes) you choose 
        # by looking below which one gives the less nRMSE       
#         print("out serie len ",len(inp_serie))
        smooth_by_ctry.append(out_serie) 
    else:
        print('Series too short ... with only ',inp_sz,' points. will not be smoothed ')

    fig, ax = plt.subplots(figsize=(18,7))
    plt.plot(x,smooth_by_ctry[-1],"r-")
    plt.plot(x,cases[p],"b.")
    ax.set_xticks(indices_ticks)
    ax.set_xticklabels(rotulos_ticks, rotation=45)
#     plt.ylim(0,max(1,1.1*np.max(Y[-1])))
#     plt.xticks(rotation='vertical')
    plt.xlabel('onset date (from week '+weeks[0]+' to '+weeks[-1]+")")
    plt.ylabel('new daily cases')
    plt.title(" Smoothed time series of "+countries[p]+" (nRMSE: {:2f}".\
              format(np.sqrt(MSE(np.array(smooth_by_ctry[-1]),np.array(cases[p])))/np.mean(cases[p]))+")")
#     plt.title(" Smoothed time series of "+C[p]+" (RMSE: {:2f}".format(np.sqrt(MSE(np.array(smooth_by_ctry[-1]),np.array(Y[p]))))+")")
#     plt.grid()
    for i in range(len(year_lims)):
        plt.plot([year_lims[i],year_lims[i]],[0,np.max(cases[p])],"k:")
#  creates directories for each country and save the figure
    plt.savefig(f'{new_dataset_dir}/{countries[p]}_raw_and_smoothed_data_from_week_{weeks[0]}-{weeks[-1]}.jpeg', format='jpeg') 
    plt.close()


# # salva csv com os dados originais e suavizados para o treinamento de cada pais, 
# # salva no diretorio de cada pais

# In[18]:


# salvando a arquivo

weeksstr = ["'"+numero+"'" for numero in weeks]

for i in range(nctry):
    # Create a pandas DataFrame
    datos = {'Date': weeksstr, 'Dengue Cases': cases[i], 'Smoothed Dengue Cases': smooth_by_ctry[i]}
    df = pd.DataFrame(datos)
    output_file = f'{new_dataset_dir}/{countries[i]}_time_series_weeks_{weeks[0]}-{weeks[-1]}.csv'
#     output_file = f'new_dataset_dir\{countries[i]}_time_series_weeks_{weeks[0]}-{weeks[-1]}.csv'
    # Save the DataFrame to a CSV file
    df.to_csv(output_file, index=False)

