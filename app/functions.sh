#!/bin/bash

## Docker API
function docker_api {
    local scheme
    local curl_opts=(-s)
    local method=${2:-GET}
    # data to POST
    if [[ -n "${3:-}" ]]; then
        curl_opts+=(-d "$3")
    fi
    if [[ -z "$DOCKER_HOST" ]];then
        echo "Error DOCKER_HOST variable not set" >&2
        return 1
    fi
    if [[ $DOCKER_HOST == unix://* ]]; then
        curl_opts+=(--unix-socket ${DOCKER_HOST#unix://})
        scheme='http://localhost'
    else
        scheme="http://${DOCKER_HOST#*://}"
    fi
    [[ $method = "POST" ]] && curl_opts+=(-H 'Content-Type: application/json')
    curl "${curl_opts[@]}" -X${method} ${scheme}$1
}

function docker_exec {
    local id="${1?missing id}"
    local cmd="${2?missing command}"
    local data=$(printf '{ "AttachStdin": false, "AttachStdout": true, "AttachStderr": true, "Tty":false,"Cmd": %s }' "$cmd")
    exec_id=$(docker_api "/containers/$id/exec" "POST" "$data" | jq -r .Id)
    if [[ -n "$exec_id" && "$exec_id" != "null" ]]; then
        docker_api /exec/$exec_id/start "POST" '{"Detach": false, "Tty":false}'
    else
        echo "$(date "+%Y/%m/%d %T"), Error: can't exec command ${cmd} in container ${id}. Check if the container is running." >&2
        return 1
    fi
}

function docker_restart {
    local id="${1?missing id}"
    docker_api "/containers/$id/restart" "POST"
}

function docker_kill {
    local id="${1?missing id}"
    local signal="${2?missing signal}"
    docker_api "/containers/$id/kill?signal=$signal" "POST"
}

function labeled_cid {
    docker_api "/containers/json" | jq -r '.[] | select(.Labels["'$1'"])|.Id'
}

function is_docker_gen_container {
    local id="${1?missing id}"
    if [[ $(docker_api "/containers/$id/json" | jq -r '.Config.Env[]' | egrep -c '^DOCKER_GEN_VERSION=') = "1" ]]; then
        return 0
    else
        return 1
    fi
}

function get_docker_gen_container {
    # First try to get the docker-gen container ID from the container label.
    local docker_gen_cid="$(labeled_cid com.github.aegypius.mkcert-for-nginx-proxy.docker_gen)"

    # If the labeled_cid function dit not return anything and the env var is set, use it.
    if [[ -z "$docker_gen_cid" ]] && [[ -n "${NGINX_DOCKER_GEN_CONTAINER:-}" ]]; then
        docker_gen_cid="$NGINX_DOCKER_GEN_CONTAINER"
    fi

    # If a container ID was found, output it. The function will return 1 otherwise.
    [[ -n "$docker_gen_cid" ]] && echo "$docker_gen_cid"
}

function get_nginx_proxy_container {
    local volumes_from
    # First try to get the nginx container ID from the container label.
    local nginx_cid="$(labeled_cid com.github.aegypius.mkcert-for-nginx-proxy.nginx_proxy)"

    # If the labeled_cid function dit not return anything ...
    if [[ -z "${nginx_cid}" ]]; then
        # ... and the env var is set, use it ...
        if [[ -n "${NGINX_PROXY_CONTAINER:-}" ]]; then
            nginx_cid="$NGINX_PROXY_CONTAINER"
        # ... else try to get the container ID with the volumes_from method.
        elif [[ $(get_self_cid) ]]; then
            volumes_from=$(docker_api "/containers/$(get_self_cid)/json" | jq -r '.HostConfig.VolumesFrom[]' 2>/dev/null)
            for cid in $volumes_from; do
                cid="${cid%:*}" # Remove leading :ro or :rw set by remote docker-compose (thx anoopr)
                if [[ $(docker_api "/containers/$cid/json" | jq -r '.Config.Env[]' | egrep -c '^NGINX_VERSION=') = "1" ]];then
                    nginx_cid="$cid"
                    break
                fi
            done
        fi
    fi

    # If a container ID was found, output it. The function will return 1 otherwise.
    [[ -n "$nginx_cid" ]] && echo "$nginx_cid"
}

function get_self_cid {
    local self_cid

    # Try the /proc files methods first then resort to the Docker API.
    if [[ -f /proc/1/cpuset ]]; then
        self_cid="$(basename "$(cat /proc/1/cpuset)")"
    elif [[ -f /proc/self/cgroup ]]; then
        self_cid="$(basename "$(cat /proc/self/cgroup | head -n 1)")"
    else
        self_cid="$(docker_api "/containers/$(hostname)/json" | jq -r '.Id')"
    fi

    # If it's not 64 characters long, then it's probably not a container ID.
    if [[ ${#self_cid} == 64 ]]; then
        echo "$self_cid"
    else
        echo "$(date "+%Y/%m/%d %T"), Error: can't get my container ID !" >&2
        return 1
    fi
}

## Nginx
function reload_nginx {
    local _docker_gen_container=$(get_docker_gen_container)
    local _nginx_proxy_container=$(get_nginx_proxy_container)

    if [[ -n "${_docker_gen_container:-}" ]]; then
        # Using docker-gen and nginx in separate container
        echo "Reloading nginx docker-gen (using separate container ${_docker_gen_container})..."
        docker_kill "${_docker_gen_container}" SIGHUP

        if [[ -n "${_nginx_proxy_container:-}" ]]; then
            # Reloading nginx in case only certificates had been renewed
            echo "Reloading nginx (using separate container ${_nginx_proxy_container})..."
            docker_kill "${_nginx_proxy_container}" SIGHUP
        fi
    else
        if [[ -n "${_nginx_proxy_container:-}" ]]; then
            echo "Reloading nginx proxy (${_nginx_proxy_container})..."
            docker_exec "${_nginx_proxy_container}" \
                '[ "sh", "-c", "/app/docker-entrypoint.sh /usr/local/bin/docker-gen /app/nginx.tmpl /etc/nginx/conf.d/default.conf; /usr/sbin/nginx -s reload" ]' \
                | sed -rn 's/^.*([0-9]{4}\/[0-9]{2}\/[0-9]{2}.*$)/\1/p'
            [[ ${PIPESTATUS[0]} -eq 1 ]] && echo "$(date "+%Y/%m/%d %T"), Error: can't reload nginx-proxy." >&2
        fi
    fi
}
