#!/bin/bash

# This script checks the number of versions of the documentation and deletes the
# oldest versions, after which it updates index.html and _config.yml with the version data.
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
doc_version_folders=($(find docs -maxdepth 1 -type d -name "[0-9].[0-9].[0-9]" | awk -F/ '{print $NF}' | sort -Vr))

# Remove oldest doc versions if size is bigger than passed.
if [ ${#doc_version_folders[@]} -gt $versions_count ]; then
  folders_to_delete=("${doc_version_folders[@]:$versions_count}")
  for folder in "${folders_to_delete[@]}"; do
    echo "Deleting old version: $folder"
    rm -rf "docs/$folder"
    rm -rf "docs/tutorials/_$folder"
  done
  doc_version_folders=("${doc_version_folders[@]:0:$versions_count}")
fi

# Generate strings with versions to pass into index.html and _config.yml
html_template_file="scripts/templates/index-template.html"
yml_template_file="scripts/templates/config-template.yml"
html_output_file="docs/index.html"
yml_output_file="docs/_config.yml"
html_version_list=""
jekyll_collection_list=""
just_docs_collection_list=""

for folder in "${doc_version_folders[@]}"; do
  html_version_list+="<li><a href=\"$folder/\">SDK v.$folder</a></li>\n"
  jekyll_collection_list+="  $folder:    \noutput: true\n"
  just_docs_collection_list+="    $folder:\n        name: SDK v$folder\n    nav_fold: true\n"
done

# Update <!-- version_list --> inside index-template.html with the new versions
# and pass updated content from index-template.html to index.html
sed "s|<!-- version_list -->|$html_version_list|" "$html_template_file" > "$html_output_file"
echo "✅ index.html updated with the new versions: $doc_version_folders"

# Update <!-- jekyll_collection_list --> and <!-- just_docs_collection_list --> inside config-template.yml
# with the new versions and pass updated content from config-template.yml to _config.yml
yml_content=$(<"$yml_template_file")
updated_yml_content=$(echo "$yml_content" | sed "s|<!-- jekyll_collection_list -->|$jekyll_collection_list|")
updated_yml_content=$(echo "$updated_yml_content" | sed "s|<!-- just_docs_collection_list -->|$just_docs_collection_list|")
echo "$updated_yml_content" > "$yml_output_file"
echo "$updated_yml_content"
echo "✅ _config.yml updated with the new versions: $doc_version_folders"