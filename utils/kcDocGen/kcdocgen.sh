#!/bin/sh

#| # kcDocGen
#|
#| A simple README generator for source code documentation.
#|
#| `kcdocgen` is a shell function that extracts all comments beginning with `#|` 
#| from an input file, and writes the content out to a README file. 
#| 
#| This allows you to write Markdown documentation directly in your source code. 
#| See the code comments in `kcdocgen.sh` for an example.  
#| 
#| ## Setup
#|
#| ```sh
#| kcScriptUrl="https://raw.githubusercontent.com/CaseyLabs/kcUtils/main/utils/kcDocGen/kcdocgen.sh"
#| curl -s ${kcScriptUrl} > kcdocgen
#| chmod +x kcdocgen
#| sudo mv kcdocgen /usr/local/bin/
#| ```
#|
#| ## Usage
#|
#| ```sh
#| kcdocgen input_file
#| ```
#|
#| ## Example
#|
#| Example: `kcdocgen mycode.py`
#|
#| Let's say you have a Python file called `mycode.py` with the following content:
#|
#| ```python  
#| #| # Example  
#| #| This is an example of text we want to include in the README.  
#| #|  
#| #| ## Usage  
#| #|  
#| #| ```python  
#| #| python example.py  
#| #| ```  
#| #|  
#| #| ## Output  
#| #| Hello, World!  
#|   
#| print("Hello, World!")  
#| print("Don't include this code in the readme!")  
#|   
#| # This comment won't be added to the readme because it 
#| # is a regular comment...
#| print("Last line!")  
#| ```  
#|
#| `kcdocgen mycode.py` will parse every line for `#|` and generate a README file 
#| from those comments. The generated readme file content will look like:
#|
#| <pre>
#| # Example
#|
#| This is an example of text we want to include in the README. 
#|
#| ## Usage
#| 
#| ```python
#| python example.py
#| ```
#|
#| ## Output
#|
#| Hello, World!
#| </pre>
#|
#| The README file will be saved as `readme_mycode.py.md` in the current folder.
#|
#| ## Demo
#| ![Image of kcDocGen running](./demo.gif)

serviceName="kcdocgen"
marker="#|"

# Logging function
log() {
  level=$1
  message=$2
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  printf "[%s] [%s] [%s] %s\n" "$level" "$timestamp" "$serviceName" "$message"
}

# Sanitize input file to avoid './' issues
sanitize_filename() {
  filename=$(basename "$1")
  echo "$filename"
}

# Function to process a single file
process_file() {
  input_file="$1"
  readme_file="$2"

  in_code_block=0
  code_block_depth=0
  
  # Read the entire file into an array
  mapfile -t lines < <(grep "$marker" "$input_file")
  
  for line in "${lines[@]}"; do
    # Remove the marker and leading whitespace
    line="${line#*$marker}"
    line="${line#"${line%%[![:space:]]*}"}"
    
    # Check for code block delimiters
    if [[ "$line" == *'```'* ]]; then
      if [ $in_code_block -eq 0 ]; then
        in_code_block=1
        code_block_depth=0
      else
        if [[ "$line" == *'```'*'```'* ]]; then
          # Handle case where ``` appears twice in the same line
          in_code_block=0
        else
          if [ $code_block_depth -eq 0 ]; then
            in_code_block=0
          fi
          code_block_depth=$((1 - code_block_depth))
        fi
      fi
      printf '%s\n' "$line" >> "$readme_file"
      continue
    fi
    
    # Handle content inside and outside code blocks
    if [ $in_code_block -eq 1 ]; then
      # Inside a code block, remove any remaining #| markers
      line="${line#"#|"}"
      line="${line#"${line%%[![:space:]]*}"}"
      printf '%s\n' "$line" >> "$readme_file"
    else
      # Outside code blocks
      case "$line" in
        -*)
          printf "%s\n\n" "$line" >> "$readme_file"  # List items with extra newline
          ;;
        *)
          printf "%s\n" "$line" >> "$readme_file"  # Normal lines without extra spaces
          ;;
      esac
    fi
  done

  # If still inside a code block, close it
  if [ $in_code_block -eq 1 ]; then
    printf '```\n' >> "$readme_file"
  fi

  # Remove any trailing quotation marks
  sed -i '$ s/"$//' "$readme_file"
}

# Check if an input file or folder was provided
if [ $# -eq 0 ]; then
  log "error" "No input file or folder provided"
  echo "Usage: $0 [--recursive] input_file"
  exit 1
fi

input_file="$1"
sanitized_file=$(sanitize_filename "$input_file")

if [ "$1" = "--recursive" ]; then
  readme_file="README.md"
  [ -f "$readme_file" ] && rm "$readme_file"

  find . -type f -print0 | while IFS= read -r -d '' file; do
    process_file "$file" "$readme_file"
    printf "\n---\n" >> "$readme_file"
  done
else
  readme_file="readme_${sanitized_file}.md"
  [ -f "$readme_file" ] && rm "$readme_file"

  if [ ! -f "$input_file" ]; then
    log "error" "Input file does not exist: $input_file"
    echo "Error: Input file does not exist: $input_file"
    exit 1
  fi

  process_file "$input_file" "$readme_file"
fi

if [ ! -f "$readme_file" ]; then
  log "error" "Failed to create output file: $readme_file"
  echo "Error: Failed to create output file: $readme_file"
  exit 1
fi

log "info" "Finished. Output file: $readme_file"