#!/bin/bash

# Verifies if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <directory_of_data> <data_file>"
    exit 1
fi

# Directory where the file of countries is located
directory_of_data="$1"

# Name of the file containing the list of countries
data_file="$2"

# Output file for echo statements
output_file="$(dirname "$0")/preprocessor_output.log"

# Remove the output log file if it exists
[ -e "$output_file" ] && rm "$output_file"

echo "Preprocessor Script (author: Dr. Diego Frias, 2023, diegofriass@gmail.com)" >> "$output_file"

echo "directory_of_data: ${directory_of_data}"
echo "data_file: ${data_file}" # Redirect the output of echo statements to the output file
echo "directory_of_data: ${directory_of_data}" >> "$output_file"
echo "data_file: ${data_file}" >> "$output_file"

# Full path to the file of countries
full_path_to_data_file="${directory_of_data}/${data_file}"

# Check if the file exists
if [ ! -f "$full_path_to_data_file" ]; then
    echo "Error: File '${full_path_to_data_file}' not found."
    exit 1
fi

# Execute the Python program with the directory and country as separate arguments
python ../apps/preprocessor-2-py.py --directory "${directory_of_data}" --file "${data_file}"

echo "PREPROCESSING TASK ENDED ................."
