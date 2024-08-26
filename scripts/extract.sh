#!/bin/bash

# Define source directory (current directory by default)
SRC_DIR="${1:-.}"

# Define destination directories
IMG_DIR="Images"
DOC_DIR="Documents"
PDF_DIR="PDFs"
CODE_DIR="CodeFiles"

# Create destination directories if they don't exist
mkdir -p "$IMG_DIR" "$DOC_DIR" "$PDF_DIR" "$CODE_DIR"

# Find and move image files
find "$SRC_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" \) -exec cp {} "$IMG_DIR" \; -exec bash -c 'file="$1"; base_file="$(basename "$file")"; cat << EOF > "Images/${base_file}.json"
{
    "name": "$(basename "$file")",
    "folder/description": "$folder",
    "semester": "",
    "subject": "",
    "specialization": "",
    "is_exam": "",
    "url": "",
    "keywords": "",
    "vaults": ""
}
EOF
' _ {} \;

# Find and move Word documents
find "$SRC_DIR" -type f \( -iname "*.doc" -o -iname "*.docx" \) -exec cp {} "$DOC_DIR" \; -exec bash -c 'file="$1"; base_file="$(basename "$file")"; cat << EOF > "Documents/${base_file}.json"
{
    "name": "$(basename "$file")",
    "folder/description": "$folder",
    "semester": "",
    "subject": "",
    "specialization": "",
    "is_exam": "",
    "url": "",
    "keywords": "",
    "vaults": ""
}
EOF
' _ {} \;

# Find and move PDF files
find "$SRC_DIR" -type f -iname "*.pdf" -exec cp {} "$PDF_DIR" \; -exec bash -c 'file="$1"; base_file="$(basename "$file")"; cat << EOF > "PDFs/${base_file}.json"
{
    "name": "$(basename "$file")",
    "folder/description": "$folder",
    "semester": "",
    "subject": "",
    "specialization": "",
    "is_exam": "",
    "url": "",
    "keywords": "",
    "vaults": ""
}
EOF
' _ {} \;

# Find and move code files
find "$SRC_DIR" -type f \( -iname "*.c" -o -iname "*.cpp" -o -iname "*.py" -o -iname "*.java" -o -iname "*.js" -o -iname "*.html" -o -iname "*.css" \) -exec cp {} "$CODE_DIR" \; -exec bash -c 'file="$1"; base_file="$(basename "$file")"; cat << EOF > "CodeFiles/${base_file}.json"
{
    "name": "$(basename "$file")",
    "folder/description": "$folder",
    "semester": "",
    "subject": "",
    "specialization": "",
    "is_exam": "",
    "url": "",
    "keywords": "",
    "vaults": ""
}
EOF
' _ {} \;

echo "Files have been sorted and moved to their respective directories, and JSON files have been created."
