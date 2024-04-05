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
#| sudo cp kcdocgen /usr/local/bin/
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
#| from those comments. The genereated readme file content will look like:
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

# Default: the input will parse comments that start with `#|`
marker="#|"

# Logging function
log() {
  level=$1
  message=$2
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  printf "[%s] [%s] [%s] %s\n" "$level" "$timestamp" "$serviceName" "$message"
}

# Check if an input file was provided
if [ $# -eq 0 ]; then
  log "error" "No input file provided"
  exit 1
fi

# The input file you want to extract comments from
input_file="$1"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
  log "error" "Input file does not exist: $input_file"
  exit 1
fi

# The output README file
input_file_name=$(basename "$input_file")

readme_file="readme_${input_file_name}.md"

# Remove the old README file if it exists
if [ -f "$readme_file" ]; then
  rm "$readme_file"
fi

# Extract comments and write them to the README file
in_code_block=0
grep "$marker" "$input_file" | while IFS= read -r line
do
  # Remove the marker characters at the start of the line
  line="${line#*$marker}"

  # Trim leading spaces
  line="${line#"${line%%[![:space:]]*}"}"

  # Check if the line starts or ends a code block
  case "$line" in
    *'```'*|*"<pre>"*)
      in_code_block=$((!in_code_block))
      ;;
  esac

  # Write the line to the README file, adding two spaces at the end if not in a code block
  if [ $in_code_block -eq 1 ]; then
    printf "%s\n" "$line" >> "$readme_file"
  else
    printf "%s  \n" "$line" >> "$readme_file"
  fi

done

# If the last line was inside a code block, add an extra line to end the code block
if [ $in_code_block -eq 1 ]; then
  printf '```\n' >> "$readme_file"
fi

# Check if the output file was created
if [ ! -f "$readme_file" ]; then
  log "error" "Failed to create output file: $readme_file"
  exit 1
fi

# Output a success message along with the name of the output file
log "info" "Finished. Output file: $readme_file"