#!/bin/bash

# SIGTERM-handler
term_handler() {
    [[ -n "$docker_gen_pid" ]] && kill $docker_gen_pid
    [[ -n "$mkcert_pid" ]] && kill $mkcert_pid

    exit 0
}

trap 'term_handler' INT QUIT TERM

/app/mkcert-service & mkcert_service_pid=$!

docker-gen -watch -notify '/app/signal-mkcert-service' -wait 3s:60s /app/mkcert-gen.tmpl /app/mkcert-gen & docker_gen_pid=$!

# wait "indefinitely"
while [[ -e /proc/$docker_gen_pid ]]; do
    wait $docker_gen_pid # Wait for any signals or end of execution of docker-gen
done

# Stop container properly
term_handler
