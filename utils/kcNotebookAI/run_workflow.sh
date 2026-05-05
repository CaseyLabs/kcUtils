#!/usr/bin/env sh

set -eu

STATE_FILE=".workflow_state.json"
INPUT_DIR="input"
PROCESSED_DIR="${INPUT_DIR}/processed"
TARGETS_FILE="targets.md"
OUTPUT_DIR="output"
SUMMARY_FILE="${OUTPUT_DIR}/summary.md"
EVIDENCE_FILE="${OUTPUT_DIR}/source-evidence.md"
NOTEBOOK_KEY="knowledge:notebook"
NOTEBOOK_TITLE="${NOTEBOOK_TITLE:-Knowledge Summarizer}"
NLM_QUERY_TIMEOUT="${NLM_QUERY_TIMEOUT:-600}"
NLM_SOURCE_WAIT_TIMEOUT="${NLM_SOURCE_WAIT_TIMEOUT:-600}"
EXECUTE=0
VERIFY=0
CHECK_REMOTE=0
MODE_SELECTIONS=0
NLM_PROFILE="${NLM_PROFILE:-}"
GEMINI_MODEL_NAME="${GEMINI_MODEL:-pro}"

usage() {
	printf '%s\n' "Usage: ./run_workflow.sh [--dry-run] [--execute] [--verify] [--check-remote] [--profile NAME] [--model MODEL] [--query-timeout SECONDS] [--source-wait-timeout SECONDS]"
	printf '%s\n' ""
	printf '%s\n' "Default mode is --dry-run."
	printf '%s\n' "The workflow uses one reusable NotebookLM notebook for the PDF corpus in ${INPUT_DIR}/."
	printf '%s\n' "After successful upload, pending PDFs are moved to ${PROCESSED_DIR}/."
	printf '%s\n' "If ${TARGETS_FILE} exists, it is treated as the hard scope for the generated summary."
	printf '%s\n' "NotebookLM corpus queries default to ${NLM_QUERY_TIMEOUT} seconds; override with --query-timeout or NLM_QUERY_TIMEOUT."
	printf '%s\n' "NotebookLM source processing waits default to ${NLM_SOURCE_WAIT_TIMEOUT} seconds; override with --source-wait-timeout or NLM_SOURCE_WAIT_TIMEOUT."
	printf '%s\n' "--verify refreshes ${EVIDENCE_FILE} and ${SUMMARY_FILE} from the prepared notebook."
	printf '%s\n' "--check-remote validates the recorded notebook and compares remote sources with local processed PDFs."
}

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		printf '%s\n' "Missing required command: $1" >&2
		exit 1
	fi
}

nlm_cmd() {
	if [ -n "$NLM_PROFILE" ]; then
		nlm "$@" --profile "$NLM_PROFILE"
	else
		nlm "$@"
	fi
}

append_state_run() {
	tmp_file="${STATE_FILE}.tmp"
	jq \
		--arg mode "$1" \
		--arg status "$2" \
		'.runs = ((.runs // []) + [{mode: $mode, status: $status, at: now | todate}])' \
		"$STATE_FILE" >"$tmp_file"
	mv "$tmp_file" "$STATE_FILE"
}

ensure_state_file() {
	if [ ! -f "$STATE_FILE" ]; then
		printf '%s\n' '{"version":3,"notebooks":{},"summaries":{},"runs":[]}' >"$STATE_FILE"
	fi

	tmp_file="${STATE_FILE}.tmp"
	jq \
		'.version = 3
		| .notebooks = (.notebooks // {})
		| .summaries = (.summaries // {})
		| .runs = (.runs // [])' \
		"$STATE_FILE" >"$tmp_file"
	mv "$tmp_file" "$STATE_FILE"
}

save_notebook_state() {
	tmp_file="${STATE_FILE}.tmp"
	jq \
		--arg key "$NOTEBOOK_KEY" \
		--arg id "$1" \
		--arg title "$2" \
		'.notebooks[$key] = ((.notebooks[$key] // {}) + {id: $id, title: $title, updated_at: (now | todate)})' \
		"$STATE_FILE" >"$tmp_file"
	mv "$tmp_file" "$STATE_FILE"
}

save_source_state() {
	tmp_file="${STATE_FILE}.tmp"
	jq \
		--arg key "$NOTEBOOK_KEY" \
		--arg path "$1" \
		--arg processed_path "$2" \
		'.notebooks[$key].sources = ((.notebooks[$key].sources // {}) + {($path): {status: "uploaded", processed_path: $processed_path, updated_at: (now | todate)}})' \
		"$STATE_FILE" >"$tmp_file"
	mv "$tmp_file" "$STATE_FILE"
}

save_output_state() {
	targets_path=""
	if [ -f "$TARGETS_FILE" ]; then
		targets_path="$TARGETS_FILE"
	fi

	tmp_file="${STATE_FILE}.tmp"
	jq \
		--arg key "knowledge-summary" \
		--arg output "$SUMMARY_FILE" \
		--arg evidence "$EVIDENCE_FILE" \
		--arg targets "$targets_path" \
		'.summaries[$key] = {output: $output, evidence: $evidence, targets: (if ($targets | length) > 0 then $targets else null end), updated_at: (now | todate)}' \
		"$STATE_FILE" >"$tmp_file"
	mv "$tmp_file" "$STATE_FILE"
}

normalize_markdown_output() {
	output_path="$1"
	first_line="$(sed -n '1p' "$output_path")"
	last_line="$(tail -n 1 "$output_path")"
	if printf '%s\n' "$first_line" | grep -Eq '^```(markdown)?[[:space:]]*$' && [ "$last_line" = '```' ]; then
		tmp_file="${output_path}.tmp"
		sed '1d;$d' "$output_path" >"$tmp_file"
		mv "$tmp_file" "$output_path"
	fi
}

check_markdown_output() {
	output_path="$1"
	if [ ! -s "$output_path" ]; then
		printf '%s\n' "Gemini returned an empty summary." >&2
		return 1
	fi
	if grep -Eq 'Ripgrep is not available|GrepTool|Error executing tool|Tool execution denied|You are in Plan Mode|write_file|WriteFile|ReadFile' "$output_path"; then
		printf '%s\n' "Gemini output included workflow/tool status instead of only summary markdown." >&2
		return 1
	fi
	if ! awk '
		/^## References[[:space:]]*$/ { references = 1; next }
		!references && /\[[0-9]+\]/ { inline_citation = 1 }
		END { exit inline_citation ? 0 : 1 }
	' "$output_path"; then
		printf '%s\n' "Gemini output is missing numbered inline citations such as [1]." >&2
		return 1
	fi
	if ! awk '
		/^## References[[:space:]]*$/ { references = 1; next }
		references && /^[[:space:]]*[0-9]+\.[[:space:]]+[^[:space:]]/ { reference_item = 1 }
		END { exit references && reference_item ? 0 : 1 }
	' "$output_path"; then
		printf '%s\n' "Gemini output is missing a populated ## References section with a numbered Markdown list." >&2
		return 1
	fi
}

lint_markdown_output() {
	output_path="$1"
	if ! command -v markdownlint >/dev/null 2>&1; then
		return 0
	fi
	if [ -f ".markdownlint.json" ]; then
		markdownlint --fix -c .markdownlint.json "$output_path"
		markdownlint -c .markdownlint.json "$output_path"
	else
		markdownlint --fix "$output_path"
		markdownlint "$output_path"
	fi
}

clean_gemini_stderr() {
	input_path="$1"
	output_path="$2"
	grep -v '^Ripgrep is not available\. Falling back to GrepTool\.$' "$input_path" >"$output_path" || true
}

query_notebook() {
	notebook_id="$1"
	prompt_path="$2"
	output_path="$3"
	context="$4"
	query_stderr="$(mktemp)"

	if ! nlm_cmd notebook query "$notebook_id" "$(cat "$prompt_path")" --timeout "$NLM_QUERY_TIMEOUT" >"$output_path" 2>"$query_stderr"; then
		printf '%s\n' "NotebookLM query failed for $context:" >&2
		cat "$query_stderr" >&2
		rm -f "$query_stderr"
		return 1
	fi
	rm -f "$query_stderr"

	if [ ! -s "$output_path" ]; then
		printf '%s\n' "NotebookLM returned an empty response for $context." >&2
		return 1
	fi
}

pdf_manifest() {
	find "$1" -maxdepth 1 -type f -name '*.pdf' | sort
}

positive_number() {
	printf '%s\n' "$1" | awk '/^[0-9]+([.][0-9]+)?$/ && ($1 + 0) > 0 { valid = 1 } END { exit valid ? 0 : 1 }'
}

json_collection_count() {
	json_path="$1"
	jq -r '
		if type == "array" then length
		elif (.sources? | type) == "array" then .sources | length
		elif (.items? | type) == "array" then .items | length
		elif (.data? | type) == "array" then .data | length
		else "unknown"
		end
	' "$json_path"
}

check_remote_sources() {
	notebook_id="$1"
	notebook_details="$(mktemp)"
	remote_sources="$(mktemp)"
	remote_strings="$(mktemp)"
	missing_sources="$(mktemp)"

	if ! nlm_cmd notebook get "$notebook_id" --json >"$notebook_details"; then
		rm -f "$notebook_details" "$remote_sources" "$remote_strings" "$missing_sources"
		printf '%s\n' "Recorded NotebookLM notebook is not accessible: $notebook_id" >&2
		return 1
	fi
	if ! nlm_cmd source list "$notebook_id" --json >"$remote_sources"; then
		rm -f "$notebook_details" "$remote_sources" "$remote_strings" "$missing_sources"
		printf '%s\n' "Could not list remote sources for NotebookLM notebook: $notebook_id" >&2
		return 1
	fi

	jq -r '.. | strings' "$remote_sources" >"$remote_strings"
	: >"$missing_sources"

	while IFS= read -r processed_path; do
		[ -n "$processed_path" ] || continue
		file_name="$(basename "$processed_path")"
		if ! grep -Fqx -- "$file_name" "$remote_strings" && ! grep -Fq -- "$file_name" "$remote_strings"; then
			printf '%s\n' "$processed_path" >>"$missing_sources"
		fi
	done <"$processed_pdf_list"

	printf '%s\n' "Remote notebook: $notebook_id"
	printf '%s\n' "Remote sources: $(json_collection_count "$remote_sources")"
	printf '%s\n' "Local processed PDFs: $processed_count"

	if [ -s "$missing_sources" ]; then
		printf '%s\n' "Processed PDFs not found in remote source metadata:" >&2
		sed 's/^/- /' "$missing_sources" >&2
		rm -f "$notebook_details" "$remote_sources" "$remote_strings" "$missing_sources"
		return 1
	fi

	printf '%s\n' "Remote check passed."
	rm -f "$notebook_details" "$remote_sources" "$remote_strings" "$missing_sources"
}

while [ "$#" -gt 0 ]; do
	case "$1" in
	--dry-run)
		MODE_SELECTIONS=$((MODE_SELECTIONS + 1))
		EXECUTE=0
		VERIFY=0
		CHECK_REMOTE=0
		;;
	--execute)
		MODE_SELECTIONS=$((MODE_SELECTIONS + 1))
		EXECUTE=1
		VERIFY=0
		CHECK_REMOTE=0
		;;
	--verify)
		MODE_SELECTIONS=$((MODE_SELECTIONS + 1))
		EXECUTE=0
		VERIFY=1
		CHECK_REMOTE=0
		;;
	--check-remote)
		MODE_SELECTIONS=$((MODE_SELECTIONS + 1))
		EXECUTE=0
		VERIFY=0
		CHECK_REMOTE=1
		;;
	--profile)
		if [ "$#" -lt 2 ]; then
			usage >&2
			exit 1
		fi
		NLM_PROFILE="$2"
		shift
		;;
	--model)
		if [ "$#" -lt 2 ]; then
			usage >&2
			exit 1
		fi
		GEMINI_MODEL_NAME="$2"
		shift
		;;
	--query-timeout)
		if [ "$#" -lt 2 ]; then
			usage >&2
			exit 1
		fi
		NLM_QUERY_TIMEOUT="$2"
		shift
		;;
	--source-wait-timeout)
		if [ "$#" -lt 2 ]; then
			usage >&2
			exit 1
		fi
		NLM_SOURCE_WAIT_TIMEOUT="$2"
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	--week)
		printf '%s\n' "--week is no longer supported; this project now creates one corpus summary." >&2
		usage >&2
		exit 1
		;;
	*)
		printf '%s\n' "Unknown argument: $1" >&2
		usage >&2
		exit 1
		;;
	esac
	shift
done

if [ "$MODE_SELECTIONS" -gt 1 ]; then
	printf '%s\n' "--dry-run, --execute, --verify, and --check-remote cannot be combined." >&2
	exit 1
fi

require_command awk
require_command find
require_command grep
require_command jq

if ! positive_number "$NLM_QUERY_TIMEOUT"; then
	printf '%s\n' "Invalid NotebookLM query timeout: $NLM_QUERY_TIMEOUT" >&2
	printf '%s\n' "Use seconds as a positive number, for example: --query-timeout 600" >&2
	exit 1
fi
if ! positive_number "$NLM_SOURCE_WAIT_TIMEOUT"; then
	printf '%s\n' "Invalid NotebookLM source wait timeout: $NLM_SOURCE_WAIT_TIMEOUT" >&2
	printf '%s\n' "Use seconds as a positive number, for example: --source-wait-timeout 600" >&2
	exit 1
fi

if [ ! -d "$INPUT_DIR" ]; then
	printf '%s\n' "Missing input directory: $INPUT_DIR" >&2
	exit 1
fi

pending_pdf_list="$(mktemp)"
processed_pdf_list="$(mktemp)"
trap 'rm -f "$pending_pdf_list" "$processed_pdf_list"' EXIT

pdf_manifest "$INPUT_DIR" >"$pending_pdf_list"
if [ -d "$PROCESSED_DIR" ]; then
	pdf_manifest "$PROCESSED_DIR" >"$processed_pdf_list"
else
	: >"$processed_pdf_list"
fi

pending_count="$(wc -l <"$pending_pdf_list" | tr -d ' ')"
processed_count="$(wc -l <"$processed_pdf_list" | tr -d ' ')"

printf '%s\n' "Pending PDFs: $pending_count"
printf '%s\n' "Processed PDFs: $processed_count"
if [ -f "$TARGETS_FILE" ]; then
	printf '%s\n' "Targets: $TARGETS_FILE (hard scope)"
else
	printf '%s\n' "Targets: none (full corpus)"
fi

if [ "$EXECUTE" -ne 1 ] && [ "$VERIFY" -ne 1 ] && [ "$CHECK_REMOTE" -ne 1 ]; then
	printf '%s\n' "Dry run only. Re-run with --execute to upload pending PDFs and write ${SUMMARY_FILE}."
	printf '%s\n' "Output: $SUMMARY_FILE"
	printf '%s\n' "Evidence: $EVIDENCE_FILE"
	exit 0
fi

require_command gemini
require_command nlm

nlm_cmd login --check
if [ "$CHECK_REMOTE" -eq 1 ]; then
	if [ ! -f "$STATE_FILE" ]; then
		printf '%s\n' "Missing workflow state: $STATE_FILE. Run --execute first." >&2
		exit 1
	fi
elif [ "$VERIFY" -eq 1 ]; then
	ensure_state_file
	append_state_run "verify" "started"
else
	ensure_state_file
	append_state_run "execute" "started"
fi

notebook_id="$(jq -r --arg key "$NOTEBOOK_KEY" '.notebooks[$key].id // ""' "$STATE_FILE")"
if [ -z "$notebook_id" ]; then
	if [ "$VERIFY" -eq 1 ] || [ "$CHECK_REMOTE" -eq 1 ]; then
		printf '%s\n' "Missing prepared notebook in $STATE_FILE. Run --execute first." >&2
		exit 1
	fi
	if [ "$processed_count" -gt 0 ]; then
		printf '%s\n' "Processed PDFs exist, but no prepared corpus notebook is recorded in $STATE_FILE." >&2
		printf '%s\n' "Restore the workflow state or move those PDFs back to $INPUT_DIR/ before running --execute." >&2
		exit 1
	fi
	if [ "$pending_count" -eq 0 ]; then
		printf '%s\n' "No prepared notebook exists and there are no pending PDFs to upload." >&2
		printf '%s\n' "Place PDFs in $INPUT_DIR/ and run --execute." >&2
		exit 1
	fi
	create_output="$(nlm_cmd notebook create "$NOTEBOOK_TITLE")"
	notebook_id="$(printf '%s\n' "$create_output" | grep -Eo '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' | head -n 1 || true)"
	if [ -z "$notebook_id" ]; then
		printf '%s\n' "Could not parse notebook id from nlm output:" >&2
		printf '%s\n' "$create_output" >&2
		exit 1
	fi
	save_notebook_state "$notebook_id" "$NOTEBOOK_TITLE"
fi

if [ "$CHECK_REMOTE" -eq 1 ]; then
	if ! check_remote_sources "$notebook_id"; then
		exit 1
	fi
	printf '%s\n' "Workflow state: $STATE_FILE"
	exit 0
fi

if [ "$EXECUTE" -eq 1 ]; then
	mkdir -p "$PROCESSED_DIR"
	while IFS= read -r source_path; do
		[ -n "$source_path" ] || continue
		file_name="$(basename "$source_path")"
		processed_path="${PROCESSED_DIR}/${file_name}"
		if [ -e "$processed_path" ]; then
			printf '%s\n' "Processed file already exists: $processed_path" >&2
			printf '%s\n' "Move or rename it before uploading another PDF with the same name." >&2
			exit 1
		fi

		printf '%s\n' "Uploading: $source_path"
		nlm_cmd source add "$notebook_id" --file "$source_path" --wait --wait-timeout "$NLM_SOURCE_WAIT_TIMEOUT"
		mv "$source_path" "$processed_path"
		save_source_state "$source_path" "$processed_path"
		printf '%s\n' "Processed: $processed_path"
	done <"$pending_pdf_list"
fi

if [ "$EXECUTE" -eq 1 ]; then
	pdf_manifest "$INPUT_DIR" >"$pending_pdf_list"
	if [ -d "$PROCESSED_DIR" ]; then
		pdf_manifest "$PROCESSED_DIR" >"$processed_pdf_list"
	fi
fi

processed_count="$(wc -l <"$processed_pdf_list" | tr -d ' ')"
if [ "$processed_count" -eq 0 ]; then
	printf '%s\n' "No processed PDFs are available for summarization." >&2
	exit 1
fi

mkdir -p "$OUTPUT_DIR"
evidence_prompt="$(mktemp)"
raw_evidence="$(mktemp)"
refine_input="$(mktemp)"
refined_output="$(mktemp)"
gemini_stderr="$(mktemp)"
clean_gemini_stderr_file="$(mktemp)"
trap 'rm -f "$pending_pdf_list" "$processed_pdf_list" "$evidence_prompt" "$raw_evidence" "$refine_input" "$refined_output" "$gemini_stderr" "$clean_gemini_stderr_file"' EXIT

{
	cat prompt1.txt
	printf '\n\n%s\n' "CORPUS CONTEXT:"
	printf '%s\n' "Notebook title: $NOTEBOOK_TITLE"
	printf '%s\n' "Processed source files:"
	sed 's/^/- /' "$processed_pdf_list"
	if [ -f "$TARGETS_FILE" ]; then
		printf '\n%s\n' "TARGETS_MD_HARD_SCOPE:"
		cat "$TARGETS_FILE"
		printf '\n%s\n' "Use only the pages, chapters, or topics listed in targets.md. Treat all other source content as out of scope."
	else
		printf '\n%s\n' "No targets.md was provided. Summarize the full uploaded source corpus."
	fi
} >"$evidence_prompt"

query_notebook "$notebook_id" "$evidence_prompt" "$raw_evidence" "$NOTEBOOK_TITLE"
cp "$raw_evidence" "$EVIDENCE_FILE"

{
	printf '%s\n' "CORPUS CONTEXT:"
	printf '%s\n' "Notebook title: $NOTEBOOK_TITLE"
	printf '%s\n' "Processed source files:"
	sed 's/^/- /' "$processed_pdf_list"
	if [ -f "$TARGETS_FILE" ]; then
		printf '\n%s\n' "TARGETS_MD_HARD_SCOPE:"
		cat "$TARGETS_FILE"
	else
		printf '\n%s\n' "TARGETS_MD_HARD_SCOPE: none"
	fi
	printf '\n%s\n' "NOTEBOOKLM_EVIDENCE:"
	cat "$raw_evidence"
} >"$refine_input"

if ! gemini --model "$GEMINI_MODEL_NAME" --prompt="$(cat prompt2.txt)" <"$refine_input" >"$refined_output" 2>"$gemini_stderr"; then
	clean_gemini_stderr "$gemini_stderr" "$clean_gemini_stderr_file"
	cat "$clean_gemini_stderr_file" >&2
	exit 1
fi
clean_gemini_stderr "$gemini_stderr" "$clean_gemini_stderr_file"
if [ -s "$clean_gemini_stderr_file" ]; then
	printf '%s\n' "Gemini emitted runtime warnings:" >&2
	cat "$clean_gemini_stderr_file" >&2
fi

normalize_markdown_output "$refined_output"
check_markdown_output "$refined_output"
lint_markdown_output "$refined_output"
mv "$refined_output" "$SUMMARY_FILE"
save_output_state

if [ "$EXECUTE" -eq 1 ]; then
	append_state_run "execute" "completed"
else
	append_state_run "verify" "completed"
fi

printf '%s\n' "Wrote: $SUMMARY_FILE"
printf '%s\n' "Evidence: $EVIDENCE_FILE"
printf '%s\n' "Workflow state: $STATE_FILE"
