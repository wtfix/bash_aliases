#!/bin/bash


q() {
    local input="$*"

    if [ -z "$input" ]; then
        echo "Usage: q <your question or prompt>"
        echo "Examples:"
        echo "  q what is docker"
        echo "  q explain kubernetes pods"
        echo "  q \"How to write clean code?\""
        return 1
    fi

    pi -p "$input" | __bash_aliases_run_highlighter
}


qq() {
    local input="$*"

    if [ -z "$input" ]; then
        echo "Usage: qq <your question or prompt>"
        echo "Examples:"
        echo "  qq which one is biggest?"
        return 1
    fi

    pi -c -p "$input" | __bash_aliases_run_highlighter
}


qqq() {
    pi -c "$*"
}


# Function to handle API key retrieval
get_api_key() {
    # Replace this with your actual method of storing and retrieving the API key
    echo "$MISTRAL_API_KEY"
}

# Ask the AI about a bash command / get a shell snippet
qbash() {
    local input="$1"

    # Check if input is empty
    if [ -z "$input" ]; then
        echo "Error: No input provided."
        return 1
    fi

    # Limit input length to prevent excessive API calls
    local max_length=1000
    if [ ${#input} -gt $max_length ]; then
        echo "Warning: Input exceeds $max_length characters. Truncated to $max_length."
        input="${input:0:$max_length}"
    fi

    # Get API key
    local api_key=$(get_api_key)

    # Construct API URL
    local url="https://api.mistral.ai/v1/chat/completions"

    # Set up curl command
    local curl_cmd="curl -s -X POST '$url' \
        -H 'Content-Type: application/json' \
        -d '{\"messages\": [{\"role\": \"user\", \"content\": \"$input\"}], \"model\": \"mistral-small\"}'"

    # Add API key to curl command
    curl_cmd+=" -H 'Authorization: Bearer $api_key'"

    # Execute curl command and capture output
    local json_response=$(curl -s -X POST "$url" \
        -H 'Content-Type: application/json' \
        -d '{"messages":[{"role":"user","content":"'${input}'"}],"model":"mistral-small"}' \
        -H 'Authorization: Bearer '$api_key)

    # Extract choices[0].content from JSON response
    echo "${json_response##*\"choices\":\[\[0\],{\"message\":{\"role\":\"assistant\",\"content\":\""
    echo "${json_response##*\"]}}"
}
