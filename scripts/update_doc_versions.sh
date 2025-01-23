#!/bin/bash

# This script checks the number of versions of the documentation and deletes the
# oldest versions, after which it updates index.html with the version data.
#
# It receives one parameter - the maximum number of versions that should be stored.
if [ -z "$1" ]; then
  echo "❌ Please supply a max size of documentation versions"
  echo "❌ Usage: $0 <versions_size>"
  exit 1
fi

# Move to the root dir.
cd ..

# Find all the folders with different versions of the doc, and sort them.
versions_count=$1
doc_version_folders=($(find docs -type d -name "[0-9].[0-9].[0-9]" | awk -F/ '{print $NF}' | sort -Vr))

# Remove oldest doc versions if size is bigger than passed.
if [ ${#doc_version_folders[@]} -gt $versions_count ]; then
  folders_to_delete=("${doc_version_folders[@]:$versions_count}")
  for folder in "${folders_to_delete[@]}"; do
    echo "Deleting old version: $folder"
    rm -rf "docs/$folder"
  done
  doc_version_folders=("${doc_version_folders[@]:0:$versions_count}")
fi

# Generate string with versions to pass into index.html
template_file="scripts/templates/index-template.html"
output_file="docs/index.html"
version_list=""

for folder in "${doc_version_folders[@]}"; do
  version_list+="<li><a href=\"$folder/\">SDK v.$folder</a></li>\n"
done

if [ ! -f "$template_file" ]; then
  echo "❌ Error: Template file $template_file does not exist!"
  exit 1
fi

# Update <!-- version_list --> inside index-template.html with the new versions
# and pass updated content from index-template.html to index.html
sed "s|<!-- version_list -->|$version_list|" "$template_file" > "$output_file"
echo "✅ index.html updated with the new versions: $doc_version_folders"