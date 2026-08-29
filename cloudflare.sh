
# Cloudflare AI Usage function
cf-ai-usage() {
    # Default to today (UTC)
    local date_arg="${1:-$(date -u +%Y-%m-%d)}"

    if [[ -z "$CLOUDFLARE_API_KEY" || -z "$CLOUDFLARE_ACCOUNT_ID" ]]; then
        echo "ERROR: CLOUDFLARE_API_KEY and CLOUDFLARE_ACCOUNT_ID must be set." >&2
        return 1
    fi

    # GraphQL query – limit 1 is fine; it returns the aggregated total for the day
    local query="query { viewer { accounts(filter: { accountTag: \"$CLOUDFLARE_ACCOUNT_ID\" }) { aiInferenceAdaptiveGroups(limit: 1, filter: { date: \"$date_arg\" }) { sum { totalNeurons } } } } }"

    local result
    result=$(curl -s -X POST "https://api.cloudflare.com/client/v4/graphql" \
        -H "Authorization: Bearer $CLOUDFLARE_API_KEY" \
        -H "Content-Type: application/json" \
        --data "$(jq -n --arg q "$query" '{query: $q}')" \
        | jq -r '.data.viewer.accounts[0].aiInferenceAdaptiveGroups[0].sum.totalNeurons // "null"')

    if [[ "$result" == "null" ]]; then
        echo "No usage data found for $date_arg (or error occurred)." >&2
        return 1
    else
        echo "$result"
    fi
}
