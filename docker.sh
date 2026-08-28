
alias docker-cleanup-skaffold="docker system df && docker image prune -a -f && docker builder prune --filter 'until=168h' -f && docker system df"
