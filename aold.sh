#!/bin/bash

# Auto OSS License Documentation
#
# SPDX-License-Identifier: GPL-2.0
#
# By: Jon West <electrikjesus@gmail.com>
# 
# Part of Android-Generic Project Manager
# Copyright (C) 2021-2023 Android-Generic Team


# Check for -d|--debug flag
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -d|--debug)
            DEBUG=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

target_path=$1

# Build list 1 of possible OSS LICENSE_FILE_NAMES
possible_license_filenames=(
  LICENSE
  LICENSE.txt
  LICENSE.md
  LICENSE.rtf
  LICENSE.xml
  COPYING
  COPYING.txt
  COPYING.md
  COPYING.rtf
  COPYING.xml
)

# Build list 2 of known OSS license type identifiers
known_license_types=(
  " Apache "
  "Apache-2.0"
  "BSD-3-Clause"
  " GPL "
  "GPL-2.0"
  "GPL-3.0"
  " LGPL "
  "LGPL-2.1"
  "LGPL-3.0"
  " MIT "
  " BSD "
  " AGPL "
  " MPL "
  " EPL "
)

# Build list 3 of OSS license types that require the source of any changes made to be released
required_source_license_types=(
  " GPL "
  "GPL-2.0"
  "GPL-3.0"
  " LGPL "
  "LGPL-2.1"
  "LGPL-3.0"
  " AGPL "
  " MPL "
  " EPL "
)
current_folder=$target_path
cd $current_folder

# find all .xml files within the $current_folder/.repo/manifests/ folder and assign the list to a variable
manifest_files=$(find "$current_folder/.repo/manifests/" -type f -name "*.xml")

# go through each manifest_file in the $manifest_files variable and assign that file to the default_manifest variable
for manifest_file in $manifest_files; do
  current_manifest=$manifest_file
  if [[ $DEBUG == true ]]; then
    echo "Current manifest: $current_manifest"
  fi

# Parse the default manifest file
default_manifest=$(cat $current_manifest)
while read -r line; do
  if [[ $DEBUG == true ]]; then
    echo "Line: $line"
  fi
  # if line contains "<project"
  if [[ "$line" == *"<project"* ]]; then
    # Tale the $line, and grab the variables for path= and name=
    # Example Line: <project path="packages/services/Telecomm" name="platform_packages_services_Telecomm" remote="BlissRoms" />
    
    path_var=$(echo "$line" | awk -F 'path="' '{print $2}' | awk -F '"' '{print $1}')
    name_var=$(echo "$line" | awk -F 'name="' '{print $2}' | awk -F '"' '{print $1}')

    if [[ $DEBUG == true ]]; then
      echo "path_var: $path_var"
      echo "name_var: $name_var"
    fi

    # Find license files in the specified path
    # Loop through possible license file names and find them in the specified path
    for filename in "${possible_license_filenames[@]}"; do
      lfline=$(find "$path_var" -type f -name "$filename")
      if [[ $DEBUG == true ]]; then
        echo "lfline: $lfline"
      fi
      # if $lfline does not contain "No such file or directory", add it to the licenses array
      if [[ "$lfline" == *"No such file or directory"* ]]; then
        continue
      elif [[ "$lfline" == "" ]]; then
        continue
      else
        licenses+=("$lfline")
      fi
    done
    
  fi
done <<< "$default_manifest"


done

# Create document in markdown and save to new "ag documentation" folder in project root.
mkdir -p $current_folder/ag_documentation
# Get current folder name using basename and save to variable
current_folder_name=$(basename "$current_folder")

markdown_file="$current_folder/ag_documentation/licenses.md"
cat << EOF > "$markdown_file"
List of OSS Licenses
====================

This document lists the OSS licenses used in $current_folder_name.

This document was generated using Android-Generic Project Manager's [auto-oss-license-documentation](https://github.com/android-generic/agpm-auto-oss-license-documentation) script

## License Location

EOF

for license in "${licenses[@]}"; do

  echo "" >> "$markdown_file"
  
  # for each_license_file in "$license"; do
  IFS=$'\n' read -r -d '' -a each_license_files <<< "$license"; 
  for each_license_file in "${each_license_files[@]}"; do
    # get directory name of $each_license_file
    each_license_file_dir=$(dirname "$each_license_file")

    echo "### License in: $each_license_file_dir" >> "$markdown_file"
    echo "$each_license_file" >> "$markdown_file"

    # if license file contains any of the known license types, echo that type to the file also
    for license_type in "${known_license_types[@]}"; do

      haslicense=$(grep -is "$license_type" "$each_license_file")
      if [[ -n "$haslicense" ]]; then
        echo "#### Posssible ${license_type} license found" >> "$markdown_file"
        echo "\`\`\`" >> "$markdown_file"
        echo "$haslicense" >> "$markdown_file"
        echo "\`\`\`" >> "$markdown_file"
        # If license type is one of the required_source_license_types, echo that type to the file also
        if [[ "$license_type" == "GPL" || "$license_type" == "LGPL" ]]; then
          echo "**This license might require source release**" >> "$markdown_file"
        fi
        for required_license_type in "${required_source_license_types[@]}"; do
          if [[ "$required_license_type" == "$license_type" ]]; then
            echo "**This license type requires the source of any changes made to be released**" >> "$markdown_file"
            break
          fi
        done
      fi

    done
    echo "" >> "$markdown_file"
  done
  echo "" >> "$markdown_file"
  
done

cd $PWD

echo "Done!"
echo "Saved to $markdown_file"