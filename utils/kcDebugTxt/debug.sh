#!/bin/bash

script_name=$(basename "$0")
output_file="debug.txt"

# Clear the output file if it exists
> "$output_file" 2>/dev/null || { echo "Error: Cannot write to $output_file"; exit 1; }

echo "Current time: $(date)" >> "$output_file"
echo "Let's review the current status of the entire repository, and find any errors or issues." >> "$output_file"

# Define exclusion patterns
exclude_patterns=('*/\.*' '*/node_modules*' '*/vendor*' '*/dist*' '*/build*')
exclude_args=()
for pattern in "${exclude_patterns[@]}"; do
    exclude_args+=(-not -path "$pattern")
done

# Generate tree output and file list in one pass
tree_output=$(find . "${exclude_args[@]}" \
    -type d -exec printf "%s\n" "{}" \; -o \
    -type f -not -name "$script_name" -not -name "$output_file" -exec printf "%s\n" "{}" \;)

echo "Current repo layout:" >> "$output_file"
echo "\`\`\`" >> "$output_file"
echo "$tree_output" >> "$output_file"
echo "\`\`\`" >> "$output_file"

# Process files
while IFS= read -r line; do
    if [ -f "$line" ] && [ "$(basename "$line")" != "$script_name" ] && [ "$(basename "$line")" != "$output_file" ]; then
        if [ ! -r "$line" ]; then
            echo "Warning: Cannot read '$line'" >> "$output_file"
            continue
        fi
        
        file_name=$(basename "$line")
        echo "Processing $file_name" >&2
        
        # Add language hint based on extension
        case "$file_name" in
            *.sh) lang="shell" ;;
            *.py) lang="python" ;;
            *.js) lang="javascript" ;;
            *.ts) lang="typescript" ;;
            *.go) lang="go" ;;
            *) lang="" ;;
        esac
        
        echo "fileName: \`$file_name\`" >> "$output_file"
        echo "fileContents:" >> "$output_file"
        echo "\`\`\`$lang" >> "$output_file"
        cat "$line" >> "$output_file" 2>/dev/null || echo "Error reading $line" >> "$output_file"
        echo "\`\`\`" >> "$output_file"
        echo "" >> "$output_file"
    fi
done <<< "$tree_output"

echo "Debug report generated in $output_file" >&2