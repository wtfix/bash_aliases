
openrouter-usage() {
    if [ -z "$OPENROUTER_MANAGEMENT_API_KEY" ]; then
        echo "ERROR: OPENROUTER_MANAGEMENT_API_KEY is not set."
        return 1
    fi

    local start_date=$(date -u +%Y-%m-%d)T00:00:00Z
    local end_date=$(date -u +%Y-%m-%d)T23:59:59Z

    local response
    response=$(curl -s --request POST \
        --url https://openrouter.ai/api/v1/analytics/query \
        --header "Authorization: Bearer $OPENROUTER_MANAGEMENT_API_KEY" \
        --header "Content-Type: application/json" \
        --data "{
            \"dimensions\": [],
            \"granularity\": \"day\",
            \"limit\": 1,
            \"metrics\": [\"request_count\", \"tokens_total\", \"cache_hit_rate\"],
            \"time_range\": {
                \"start\": \"$start_date\",
                \"end\": \"$end_date\"
            }
        }")

    if [ -n "$DEBUG" ] && [ "$DEBUG" != "0" ]; then
        echo "--- RAW RESPONSE ---"
        echo "$response" | jq .
        echo "--- END RAW ---"
    fi

    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        echo "API error:"
        echo "$response" | jq '.error'
        return 1
    fi

    # Extract the first data point
    local data
    data=$(echo "$response" | jq -c '.data.data[0]')

    if [ "$data" = "null" ] || [ -z "$data" ]; then
        echo "No usage data found for today."
        return 0
    fi

    # Pretty print as a formatted table with comma-separated numbers
    echo "$data" | jq -r '
        def commaize:
            tostring
            | split("") | reverse
            | reduce .[] as $d (
                {digits: 0, out: []};
                if .digits > 0 and (.digits % 3 == 0) then
                    .out += [",", $d] | .digits += 1
                else
                    .out += [$d] | .digits += 1
                end
            )
            | .out | reverse | join("");

        "Date:           \(.date__day)",
        "Requests:       \(.request_count | tonumber | commaize)",
        "Total Tokens:   \(.tokens_total | tonumber | commaize)",
        "Cache Hit Rate: \(if .cache_hit_rate != null then (.cache_hit_rate * 100 | floor) else 0 end)%"
    '
}

alias or-usage='openrouter-usage'

or-usage-models() {
    if [ -z "$OPENROUTER_MANAGEMENT_API_KEY" ]; then
        echo "ERROR: OPENROUTER_MANAGEMENT_API_KEY is not set."
        return 1
    fi

    local start_date=$(date -u +%Y-%m-%d)T00:00:00Z
    local end_date=$(date -u +%Y-%m-%d)T23:59:59Z

    local response
    response=$(curl -s --request POST \
        --url https://openrouter.ai/api/v1/analytics/query \
        --header "Authorization: Bearer $OPENROUTER_MANAGEMENT_API_KEY" \
        --header "Content-Type: application/json" \
        --data "{
            \"dimensions\": [\"model\"],
            \"granularity\": \"day\",
            \"limit\": 100,
            \"metrics\": [\"request_count\", \"tokens_total\", \"cache_hit_rate\"],
            \"time_range\": {
                \"start\": \"$start_date\",
                \"end\": \"$end_date\"
            }
        }")

    if [ -n "$DEBUG" ] && [ "$DEBUG" != "0" ]; then
        echo "--- RAW RESPONSE ---"
        echo "$response" | jq .
        echo "--- END RAW ---"
    fi

    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        echo "API error:"
        echo "$response" | jq '.error'
        return 1
    fi

    # Check if we have data
    local has_data
    has_data=$(echo "$response" | jq -e '.data.data | length > 0' 2>/dev/null)
    if [ "$has_data" != "true" ]; then
        echo "No usage data found for today."
        return 0
    fi

    # Produce a Markdown table (highlighted by your configured highlighter)
    echo "$response" | jq -r '
        # Portable comma insertion (no string slicing)
        def commaize:
            tostring
            | split("") | reverse
            | reduce .[] as $d (
                {digits: 0, out: []};
                if .digits > 0 and (.digits % 3 == 0) then
                    .out += [",", $d] | .digits += 1
                else
                    .out += [$d] | .digits += 1
                end
            )
            | .out | reverse | join("");

        [
            "| Model | Requests | Tokens | Cache Hit |",
            "|-------|----------|--------|-----------|"
        ] as $header
        | $header[],
          (.data.data[] | [
              .model,
              (.request_count | commaize),
              (.tokens_total | commaize),
              (if .cache_hit_rate != null then (.cache_hit_rate * 100 | floor) else 0 end | tostring + "%")
          ] | "| \(.[0]) | \(.[1]) | \(.[2]) | \(.[3]) |")
    ' | __bash_aliases_run_highlighter
}

