
or-usage() {
    if [ -z "$OPENROUTER_MANAGEMENT_API_KEY" ]; then
        echo "ERROR: OPENROUTER_MANAGEMENT_API_KEY is not set."
        return 1
    fi

    local start_date=$(date -u +%Y-%m-%d)T00:00:00Z
    local end_date=$(date -u +%Y-%m-%d)T23:59:59Z

    # Fetch per-model data
    local models_response
    models_response=$(curl -s --request POST \
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

    # Fetch summary data (for overall cache hit rate and cache timestamp)
    local summary_response
    summary_response=$(curl -s --request POST \
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
        echo "--- RAW MODELS RESPONSE ---"
        echo "$models_response" | jq .
        echo "--- RAW SUMMARY RESPONSE ---"
        echo "$summary_response" | jq .
        echo "--- END RAW ---"
    fi

    # Check for API errors
    if echo "$models_response" | jq -e '.error' >/dev/null 2>&1; then
        echo "API error in models query:"
        echo "$models_response" | jq '.error'
        return 1
    fi
    if echo "$summary_response" | jq -e '.error' >/dev/null 2>&1; then
        echo "API error in summary query:"
        echo "$summary_response" | jq '.error'
        return 1
    fi

    # Combine responses and produce the final table
    jq -r -n \
        --argjson models "$models_response" \
        --argjson summary "$summary_response" \
        '
        # Comma‑separated numbers
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

        # Percentage formatting (input is a number 0-1)
        def pct:
            (if . != null then (. * 100 | floor) else 0 end | tostring + "%");

        # Left padding
        def pad($w):
            . + (" " * ($w - length));

        # Convert Unix timestamp in ms to ISO 8601
        def ms_to_iso:
            if . != null then (. / 1000 | todateiso8601) else "unknown" end;

        $models.data.data as $data
        | $summary.data.data[0] as $summary_row
        | if ($data | length) == 0 then
            "No usage data found for today."
          else
            ($data | map(.request_count | tonumber) | add) as $total_req
            | ($data | map(.tokens_total | tonumber) | add) as $total_tok
            | ($summary_row.cache_hit_rate // 0) as $total_cache_rate
            | ($total_req | commaize) as $total_req_str
            | ($total_tok | commaize) as $total_tok_str
            | ($total_cache_rate | pct) as $total_cache_str
            # Model rows (without totals)
            | [
                $data[] | [
                    .model,
                    (.request_count | commaize),
                    (.tokens_total | commaize),
                    (.cache_hit_rate | pct)
                ]
              ] as $model_rows
            # Totals row
            | ["Totals", $total_req_str, $total_tok_str, $total_cache_str] as $totals_row
            | ["Model", "Requests", "Tokens", "Cache Hit"] as $headers
            | ( [$headers] + $model_rows + [$totals_row] ) as $all_with_headers
            | ( $all_with_headers | map(.[0] | length) | max ) as $w0
            | ( $all_with_headers | map(.[1] | length) | max ) as $w1
            | ( $all_with_headers | map(.[2] | length) | max ) as $w2
            | ( $all_with_headers | map(.[3] | length) | max ) as $w3
            | ( "  " + ($headers[0] | pad($w0)) + "  │ " + ($headers[1] | pad($w1)) + "  │ " + ($headers[2] | pad($w2)) + "  │ " + ($headers[3] | pad($w3)) + "  " ) as $header_line
            | ( $header_line | .[2:] | gsub("[^│]"; "─") | gsub("│"; "┼") | "  " + . ) as $sep_line
            # Simple dashed line for above totals (no crosses)
            | ( "  " + ("─" * ($header_line | length - 2)) ) as $sub_sep_line
            | $header_line,
              $sep_line,
              ( $model_rows[] | "  " + (.[0] | pad($w0)) + "  │ " + (.[1] | pad($w1)) + "  │ " + (.[2] | pad($w2)) + "  │ " + (.[3] | pad($w3)) + "  " ),
              $sub_sep_line,
              ( "  " + ($totals_row[0] | pad($w0)) + "  │ " + ($totals_row[1] | pad($w1)) + "  │ " + ($totals_row[2] | pad($w2)) + "  │ " + ($totals_row[3] | pad($w3)) + "  " ),
              "",
              "Cache Time: \($models.data.cachedAt // $summary.data.cachedAt | ms_to_iso)"
          end
        '
}

alias openrouter-usage='or-usage'

