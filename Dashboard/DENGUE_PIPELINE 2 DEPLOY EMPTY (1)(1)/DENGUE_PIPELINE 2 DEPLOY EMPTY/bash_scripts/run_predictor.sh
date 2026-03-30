#!/bin/bash

# Verifies if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <directory_of_preprocessed_data> <directory_of_models> <countries_file>"
    exit 1
fi

# Directory where the file of countries is located
directory_of_data="$1"

# Directory where the file of countries is located
directory_of_model="$2"

# Name of the file containing the list of countries
countries_file="$3"

# Output file for echo statements
output_file="$(dirname "$0")/predictor_output.log"

# Remove the output log file if it exists
[ -e "$output_file" ] && rm "$output_file"

echo "Predictor Script (author: Dr. Diego Frias, 2023, diegofriass@gmail.com)" >> "$output_file"

echo "directory_of_data: ${directory_of_data}"
echo "directory_of_model: ${directory_of_model}"
echo "countries_file: ${countries_file}" # Redirect the output of echo statements to the output file
echo "directory_of_data: ${directory_of_data}" >> "$output_file"
echo "directory_of_model: ${directory_of_model}" >> "$output_file"
echo "countries_file: ${countries_file}" >> "$output_file"

# Full path to the file of countries
full_path_to_countries_file="${directory_of_data}/${countries_file}"


# Check if the file exists
if [ ! -f "$full_path_to_countries_file" ]; then
    echo "Error: File '${full_path_to_countries_file}' not found."
    exit 1
fi

# Loop over each country in the file
while IFS= read -r country; do
    # Execute the Python program with the directory and country as separate arguments
    python ../apps/predictor-2-py.py --data_directory "${directory_of_data}" --model_directory "${directory_of_model}" --country "${country}"
    # Check the exit status of the last command
    if [ $? -eq 0 ]; then
        echo "Script executed successfully for country ${country}"
        echo "Script executed successfully for country ${country}" >> "$output_file"
    else
        echo "Script execution failed for country ${country}"
        echo "Script execution failed for country ${country}" >> "$output_file"
#         echo "Script execution failed" | sendmail -s "Predictor Script Failure Notification for country ${country}" diegofriass@gmail.com
    fi
    
done < "$full_path_to_countries_file"

echo "PREDICTION TASK ENDED !" >> "$output_file"
