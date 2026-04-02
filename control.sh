#!/usr/bin/env bash

set -u

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
PROJECT_ROOT="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
cd "$PROJECT_ROOT" || exit 1

ASTRO_PORT="${ASTRO_PORT:-4321}"
PREVIEW_PORT="${PREVIEW_PORT:-4322}"
SUPABASE_API_PORT="${SUPABASE_API_PORT:-54321}"
SUPABASE_DB_PORT="${SUPABASE_DB_PORT:-54322}"
SUPABASE_STUDIO_PORT="${SUPABASE_STUDIO_PORT:-54323}"
SUPABASE_INBUCKET_PORT="${SUPABASE_INBUCKET_PORT:-54324}"

ASTRO_LOG="$PROJECT_ROOT/astro_dev.log"
PREVIEW_LOG="$PROJECT_ROOT/astro_preview.log"
ASTRO_PID_FILE="$PROJECT_ROOT/.astro-dev.pid"
PREVIEW_PID_FILE="$PROJECT_ROOT/.astro-preview.pid"
SUPABASE_CONFIG="$PROJECT_ROOT/supabase/config.toml"
ENV_FILE="$PROJECT_ROOT/.env"

print_line() {
	printf '%s\n' "$1"
}

print_color() {
	printf '%b%s%b\n' "$1" "$2" "$NC"
}

print_blank() {
	printf '\n'
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

get_supabase_project_id() {
	if [ -f "$SUPABASE_CONFIG" ]; then
		awk -F'"' '/^project_id = "/ { print $2; exit }' "$SUPABASE_CONFIG"
	fi
}

SUPABASE_PROJECT_ID="${SUPABASE_PROJECT_ID:-$(get_supabase_project_id)}"
SUPABASE_KONG_CONTAINER="supabase_kong_${SUPABASE_PROJECT_ID}"
SUPABASE_DB_CONTAINER="supabase_db_${SUPABASE_PROJECT_ID}"
SUPABASE_STUDIO_CONTAINER="supabase_studio_${SUPABASE_PROJECT_ID}"

print_header() {
	if [ -t 1 ] && command_exists clear; then
		clear
	fi

	print_color "$BLUE" "Pluribeauty Control Center"
	print_color "$BLUE" "Projeto: $PROJECT_ROOT"
	print_blank
}

is_port_listening() {
	local port="$1"

	if command_exists lsof && lsof -nP -iTCP:"$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
		return 0
	fi

	if command_exists ss && ss -ltn "( sport = :$port )" 2>/dev/null | tail -n +2 | grep -q .; then
		return 0
	fi

	return 1
}

read_pid_file() {
	local pid_file="$1"

	if [ -f "$pid_file" ]; then
		cat "$pid_file"
	fi
}

pid_is_running() {
	local pid="$1"
	[ -n "$pid" ] && kill -0 "$pid" >/dev/null 2>&1
}

cleanup_pid_file() {
	local pid_file="$1"
	local pid

	pid="$(read_pid_file "$pid_file")"
	if [ -n "$pid" ] && ! pid_is_running "$pid"; then
		rm -f "$pid_file"
	fi
}

get_pid_on_port() {
	local port="$1"

	if command_exists lsof; then
		lsof -t -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | head -n 1
	fi
}

docker_available() {
	command_exists docker && docker ps >/dev/null 2>&1
}

docker_compose_available() {
	docker compose version >/dev/null 2>&1
}

docker_compose_legacy_available() {
	command_exists docker-compose && docker-compose version >/dev/null 2>&1
}

get_current_docker_context() {
	if command_exists docker; then
		docker context show 2>/dev/null
	fi
}

colima_available() {
	command_exists colima
}

colima_running() {
	if ! colima_available; then
		return 1
	fi

	colima status 2>/dev/null | grep -q '^INFO: colima is running'
}

ensure_colima_running() {
	if [ "$(get_current_docker_context)" != "colima" ]; then
		return 0
	fi

	if colima_running; then
		return 0
	fi

	if ! colima_available; then
		print_color "$RED" "Contexto Docker em colima, mas o comando 'colima' nao esta disponivel."
		return 1
	fi

	print_color "$YELLOW" "Colima detectado, iniciando a VM Docker local..."
	colima start || return 1
}

prepare_docker_host_for_supabase() {
	local current_context
	current_context="$(get_current_docker_context)"

	if [ "$current_context" != "colima" ]; then
		return 0
	fi

	local colima_socket
	local shim_socket

	colima_socket="${HOME}/.colima/default/docker.sock"
	shim_socket="/tmp/colima-docker.sock"

	if [ ! -S "$colima_socket" ]; then
		print_color "$RED" "Socket do Colima nao encontrado em ${colima_socket}."
		return 1
	fi

	ln -sfn "$colima_socket" "$shim_socket"
	export DOCKER_HOST="unix://${shim_socket}"
}

run_supabase() {
	if ! prepare_docker_host_for_supabase; then
		return 1
	fi

	npx supabase "$@"
}

supabase_start_args() {
	local current_context
	current_context="$(get_current_docker_context)"

	if [ "$current_context" = "colima" ]; then
		printf '%s\n' "--exclude" "vector,logflare"
	fi
}

supabase_cli_available() {
	command_exists npx && [ -f "$SUPABASE_CONFIG" ]
}

supabase_started() {
	if ! docker_available; then
		return 1
	fi

	docker ps --format '{{.Names}}' | grep -Fxq "$SUPABASE_KONG_CONTAINER"
}

find_conflicting_supabase_containers() {
	if ! docker_available; then
		return 0
	fi

	docker ps --format '{{.Names}}\t{{.Ports}}' | awk -F '\t' \
		-v project="$SUPABASE_PROJECT_ID" \
		-v api="$SUPABASE_API_PORT" \
		-v db="$SUPABASE_DB_PORT" \
		-v studio="$SUPABASE_STUDIO_PORT" \
		-v inbucket="$SUPABASE_INBUCKET_PORT" '
		$1 ~ /^supabase_/ &&
		$1 !~ ("_" project "$") &&
		(index($2, ":" api "->") || index($2, ":" db "->") || index($2, ":" studio "->") || index($2, ":" inbucket "->")) {
			print $1 "\t" $2
		}
	'
}

show_port_listener_details() {
	local found=0
	local port

	if ! command_exists lsof; then
		return 0
	fi

	for port in "$SUPABASE_API_PORT" "$SUPABASE_DB_PORT" "$SUPABASE_STUDIO_PORT" "$SUPABASE_INBUCKET_PORT"; do
		if lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
			if [ "$found" -eq 0 ]; then
				print_color "$YELLOW" "Listeners atuais nas portas do Supabase:"
				found=1
			fi

			lsof -nP -iTCP:"$port" -sTCP:LISTEN | tail -n +2 | awk -v current_port="$port" '
				{
					printf " - porta %s: %s (pid %s)\n", current_port, $1, $2
				}
			'
		fi
	done
}

show_supabase_conflicts() {
	local conflicts

	conflicts="$(find_conflicting_supabase_containers)"
	if [ -z "$conflicts" ]; then
		show_port_listener_details
		return 0
	fi

	print_color "$RED" "As portas do Supabase local ja estao ocupadas por outro projeto."
	print_line "$conflicts" | while IFS=$'\t' read -r name ports; do
		[ -n "$name" ] || continue
		printf ' - %s -> %s\n' "$name" "$ports"
	done

	local conflict_project_id
	conflict_project_id="$(printf '%s\n' "$conflicts" | head -n 1 | awk -F '\t' '{ sub(/^supabase_[^_]+_/, "", $1); print $1 }')"
	if [ -n "$conflict_project_id" ]; then
		print_blank
		print_line "Para liberar as portas, rode:"
		printf 'npx supabase stop --project-id %s\n' "$conflict_project_id"
	fi

	print_blank
	show_port_listener_details
}

sync_local_env() {
	if ! supabase_cli_available; then
		print_color "$RED" "Supabase CLI/config nao encontrados para sincronizar o .env."
		return 1
	fi

	local env_dump
	env_dump="$(run_supabase status -o env 2>/dev/null)" || {
		print_color "$RED" "Nao consegui ler as variaveis do Supabase local."
		return 1
	}

	local api_url anon_key publishable_key db_url studio_url
	api_url="$(printf '%s\n' "$env_dump" | awk -F= '/^API_URL=/{gsub(/"/, "", $2); print substr($0, index($0,$2)); exit}')"
	anon_key="$(printf '%s\n' "$env_dump" | awk -F= '/^ANON_KEY=/{gsub(/"/, "", $2); print substr($0, index($0,$2)); exit}')"
	publishable_key="$(printf '%s\n' "$env_dump" | awk -F= '/^PUBLISHABLE_KEY=/{gsub(/"/, "", $2); print substr($0, index($0,$2)); exit}')"
	db_url="$(printf '%s\n' "$env_dump" | awk -F= '/^DB_URL=/{gsub(/"/, "", $2); print substr($0, index($0,$2)); exit}')"
	studio_url="$(printf '%s\n' "$env_dump" | awk -F= '/^STUDIO_URL=/{gsub(/"/, "", $2); print substr($0, index($0,$2)); exit}')"

	cat >"$ENV_FILE" <<EOF
PUBLIC_SUPABASE_URL=$api_url
PUBLIC_SUPABASE_ANON_KEY=$anon_key
PUBLIC_SUPABASE_PUBLISHABLE_KEY=$publishable_key
SUPABASE_DB_URL=$db_url
SUPABASE_STUDIO_URL=$studio_url
EOF

	print_color "$GREEN" ".env sincronizado com o Supabase local."
}

env_status() {
	if [ -f "$ENV_FILE" ]; then
		local public_url
		local anon_key

		public_url="$(grep -E '^PUBLIC_SUPABASE_URL=' "$ENV_FILE" | tail -n 1 | cut -d= -f2-)"
		anon_key="$(grep -E '^PUBLIC_SUPABASE_ANON_KEY=' "$ENV_FILE" | tail -n 1 | cut -d= -f2-)"

		if [ -n "$public_url" ]; then
			print_color "$GREEN" "Env Supabase: $public_url"
		else
			print_color "$YELLOW" "Env Supabase: PUBLIC_SUPABASE_URL ausente em .env"
		fi

		if [ -n "$anon_key" ]; then
			print_color "$GREEN" "Env Anon Key: configurada"
		else
			print_color "$YELLOW" "Env Anon Key: PUBLIC_SUPABASE_ANON_KEY ausente em .env"
		fi
	else
		print_color "$YELLOW" "Env local: .env ainda nao existe"
	fi
}

check_status() {
	cleanup_pid_file "$ASTRO_PID_FILE"
	cleanup_pid_file "$PREVIEW_PID_FILE"

	print_color "$BLUE" "=== Status dos Servicos ==="

	if supabase_started; then
		print_color "$GREEN" "Supabase: Ativo (API: http://127.0.0.1:${SUPABASE_API_PORT} | Studio: http://127.0.0.1:${SUPABASE_STUDIO_PORT} | DB: 127.0.0.1:${SUPABASE_DB_PORT})"
	else
		local conflicts
		conflicts="$(find_conflicting_supabase_containers)"
		if [ -n "$conflicts" ]; then
			local foreign_project
			foreign_project="$(printf '%s\n' "$conflicts" | head -n 1 | awk -F '\t' '{ sub(/^supabase_[^_]+_/, "", $1); print $1 }')"
			print_color "$YELLOW" "Supabase: Portas ocupadas por outro projeto (${foreign_project})"
		else
			print_color "$RED" "Supabase: Inativo"
		fi
	fi

	local astro_pid
	astro_pid="$(read_pid_file "$ASTRO_PID_FILE")"
	if pid_is_running "$astro_pid" || is_port_listening "$ASTRO_PORT"; then
		print_color "$GREEN" "Astro Dev: Ativo (http://localhost:${ASTRO_PORT})"
	else
		print_color "$RED" "Astro Dev: Inativo"
	fi

	local preview_pid
	preview_pid="$(read_pid_file "$PREVIEW_PID_FILE")"
	if pid_is_running "$preview_pid" || is_port_listening "$PREVIEW_PORT"; then
		print_color "$GREEN" "Astro Preview: Ativo (http://localhost:${PREVIEW_PORT})"
	else
		print_color "$RED" "Astro Preview: Inativo"
	fi

	env_status
	print_color "$BLUE" "==========================="
	print_blank
}

show_menu() {
	print_header
	check_status

	print_line "Escolha uma opcao:"
	print_color "$GREEN" "--- Astro ---"
	print_line " 1) Iniciar Astro Dev (background)"
	print_line " 2) Parar Astro Dev"
	print_line " 3) Instalar/Atualizar dependencias"
	print_line " 4) Build do projeto"
	print_line " 5) Iniciar Astro Preview (requer build)"
	print_line " 6) Parar Astro Preview"
	print_color "$YELLOW" "--- Supabase Local (Docker) ---"
	print_line " 7) Iniciar Supabase local"
	print_line " 8) Parar Supabase local"
	print_line " 9) Reiniciar Supabase local"
	print_line "10) Resetar banco local Supabase"
	print_line "11) Status detalhado do Supabase"
	print_line "12) Aplicar migrations locais (db push)"
	print_color "$BLUE" "--- Utilitarios ---"
	print_line "13) Ver ultimas linhas do log do Astro Dev"
	print_line "14) Ver ultimas linhas do log do Preview"
	print_line "15) Sincronizar .env com Supabase local"
	print_line "16) Listar containers do Supabase local"
	print_line "17) Rodar smoke tests do projeto"
	print_line " 0) Sair"
	print_blank
}

start_astro_dev() {
	if pid_is_running "$(read_pid_file "$ASTRO_PID_FILE")" || is_port_listening "$ASTRO_PORT"; then
		print_color "$YELLOW" "Astro Dev ja parece estar rodando na porta ${ASTRO_PORT}."
		return 0
	fi

	print_color "$YELLOW" "Iniciando Astro Dev em background..."
	nohup npm run dev -- --host 0.0.0.0 --port "$ASTRO_PORT" >"$ASTRO_LOG" 2>&1 &
	echo $! >"$ASTRO_PID_FILE"
	sleep 2

	if pid_is_running "$(read_pid_file "$ASTRO_PID_FILE")"; then
		print_color "$GREEN" "Astro Dev iniciado. Logs em ${ASTRO_LOG}"
	else
		print_color "$RED" "Falha ao iniciar Astro Dev. Veja ${ASTRO_LOG}"
	fi
}

stop_process_from_pidfile_or_port() {
	local pid_file="$1"
	local port="$2"
	local label="$3"
	local pid

	pid="$(read_pid_file "$pid_file")"
	if ! pid_is_running "$pid"; then
		pid="$(get_pid_on_port "$port")"
	fi

	if [ -n "$pid" ]; then
		print_color "$YELLOW" "Parando ${label}..."
		kill "$pid" >/dev/null 2>&1 || true
		sleep 1
		if pid_is_running "$pid"; then
			kill -9 "$pid" >/dev/null 2>&1 || true
		fi
		rm -f "$pid_file"
		print_color "$GREEN" "${label} encerrado."
	else
		print_color "$RED" "${label} nao parece estar rodando."
	fi
}

start_preview() {
	if pid_is_running "$(read_pid_file "$PREVIEW_PID_FILE")" || is_port_listening "$PREVIEW_PORT"; then
		print_color "$YELLOW" "Astro Preview ja parece estar rodando na porta ${PREVIEW_PORT}."
		return 0
	fi

	if [ ! -d "$PROJECT_ROOT/dist" ]; then
		print_color "$YELLOW" "Nao encontrei build em dist/. Vou gerar antes de abrir o preview."
		npm run build || return 1
	fi

	print_color "$YELLOW" "Iniciando Astro Preview em background..."
	nohup npm run preview -- --host 0.0.0.0 --port "$PREVIEW_PORT" >"$PREVIEW_LOG" 2>&1 &
	echo $! >"$PREVIEW_PID_FILE"
	sleep 2

	if pid_is_running "$(read_pid_file "$PREVIEW_PID_FILE")"; then
		print_color "$GREEN" "Astro Preview iniciado. Logs em ${PREVIEW_LOG}"
	else
		print_color "$RED" "Falha ao iniciar Astro Preview. Veja ${PREVIEW_LOG}"
	fi
}

ensure_supabase_cli() {
	if ! supabase_cli_available; then
		print_color "$RED" "Supabase CLI/config nao encontrados. Rode 'npx supabase init' neste projeto."
		return 1
	fi

	if ! docker_available; then
		print_color "$RED" "Docker nao esta acessivel para o usuario atual."
		return 1
	fi

	return 0
}

stop_container_ids_from_file() {
	local ids_file="$1"

	if [ ! -s "$ids_file" ]; then
		return 0
	fi

	while IFS= read -r container_id; do
		[ -n "$container_id" ] || continue
		docker stop "$container_id" >/dev/null
	done <"$ids_file"
}

stop_all_running_docker_services() {
	if ! docker_available; then
		print_color "$RED" "Docker nao esta acessivel para o usuario atual."
		return 1
	fi

	local ids_file
	ids_file="$(mktemp)"

	docker ps -q >>"$ids_file"

	if docker_compose_available; then
		docker compose ps -q 2>/dev/null >>"$ids_file" || true
	fi

	if docker_compose_legacy_available; then
		docker-compose ps -q 2>/dev/null >>"$ids_file" || true
	fi

	sort -u "$ids_file" -o "$ids_file"

	if [ ! -s "$ids_file" ]; then
		rm -f "$ids_file"
		print_color "$YELLOW" "Nenhum container em execucao para parar antes de iniciar."
		return 0
	fi

	print_color "$YELLOW" "Parando containers retornados por docker ps e docker compose ps..."
	stop_container_ids_from_file "$ids_file"
	rm -f "$ids_file"
	print_color "$GREEN" "Containers em execucao foram parados."
}

cleanup_project_supabase_containers() {
	if ! docker_available; then
		print_color "$RED" "Docker nao esta acessivel para limpar containers antigos do Supabase."
		return 1
	fi

	local ids_file
	ids_file="$(mktemp)"

	docker ps -a --format '{{.ID}}\t{{.Names}}' | awk -F '\t' -v project="$SUPABASE_PROJECT_ID" '
		$2 ~ /^supabase_/ && $2 ~ ("_" project "$") {
			print $1
		}
	' >"$ids_file"

	if [ ! -s "$ids_file" ]; then
		rm -f "$ids_file"
		return 0
	fi

	print_color "$YELLOW" "Removendo containers antigos do Supabase deste projeto..."
	while IFS= read -r container_id; do
		[ -n "$container_id" ] || continue
		docker rm -f "$container_id" >/dev/null 2>&1 || true
	done <"$ids_file"

	rm -f "$ids_file"
	print_color "$GREEN" "Containers antigos do Supabase foram removidos."
}

start_supabase_local() {
	if ! ensure_supabase_cli; then
		return 1
	fi

	if supabase_started; then
		print_color "$YELLOW" "Supabase local deste projeto ja esta ativo."
		sync_local_env
		return 0
	fi

	ensure_colima_running || return 1
	stop_all_running_docker_services || return 1
	cleanup_project_supabase_containers || return 1

	local conflicts
	conflicts="$(find_conflicting_supabase_containers)"
	if [ -n "$conflicts" ]; then
		show_supabase_conflicts
		return 1
	fi

	print_color "$YELLOW" "Iniciando Supabase local..."
	if [ "$(get_current_docker_context)" = "colima" ]; then
		print_color "$YELLOW" "Colima detectado: iniciando Supabase sem vector/logflare."
	fi
	run_supabase start $(supabase_start_args) && sync_local_env
}

stop_supabase_local() {
	if ! ensure_supabase_cli; then
		return 1
	fi

	print_color "$YELLOW" "Parando Supabase local..."
	run_supabase stop --project-id "$SUPABASE_PROJECT_ID"
}

restart_supabase_local() {
	if ! ensure_supabase_cli; then
		return 1
	fi

	ensure_colima_running || return 1
	stop_all_running_docker_services || return 1
	cleanup_project_supabase_containers || return 1

	local conflicts
	conflicts="$(find_conflicting_supabase_containers)"
	if [ -n "$conflicts" ]; then
		show_supabase_conflicts
		return 1
	fi

	print_color "$YELLOW" "Reiniciando Supabase local..."
	run_supabase stop --project-id "$SUPABASE_PROJECT_ID" >/dev/null 2>&1 || true
	if [ "$(get_current_docker_context)" = "colima" ]; then
		print_color "$YELLOW" "Colima detectado: iniciando Supabase sem vector/logflare."
	fi
	run_supabase start $(supabase_start_args) && sync_local_env
}

reset_supabase_local() {
	if ! ensure_supabase_cli; then
		return 1
	fi

	print_color "$RED" "Isso vai apagar os dados locais do Supabase. Confirmar? (y/N)"
	printf 'Confirmar: '

	local confirm
	IFS= read -r confirm

	case "$confirm" in
		y|Y)
			run_supabase db reset && sync_local_env
			;;
		*)
			print_line "Operacao cancelada."
			;;
	esac
}

show_supabase_status() {
	if ! ensure_supabase_cli; then
		return 1
	fi

	run_supabase status
	print_blank

	local conflicts
	conflicts="$(find_conflicting_supabase_containers)"
	if [ -n "$conflicts" ] && ! supabase_started; then
		show_supabase_conflicts
	fi
}

push_supabase_migrations() {
	if ! ensure_supabase_cli; then
		return 1
	fi

	print_color "$YELLOW" "Aplicando migrations locais..."
	run_supabase db push
}

list_supabase_containers() {
	if ! docker_available; then
		print_color "$RED" "Docker nao esta acessivel."
		return 1
	fi

	docker ps --format '{{.Names}}\t{{.Status}}\t{{.Ports}}' | grep "supabase_.*_${SUPABASE_PROJECT_ID}" || print_line "Nenhum container do Supabase local em execucao."
}

pause_for_user() {
	print_blank
	printf 'Pressione [Enter] para continuar...'
	IFS= read -r _
}

while true; do
	show_menu
	printf 'Opcao: '
	IFS= read -r opt
	print_blank

	case "$opt" in
		1)
			start_astro_dev
			;;
		2)
			stop_process_from_pidfile_or_port "$ASTRO_PID_FILE" "$ASTRO_PORT" "Astro Dev"
			;;
		3)
			print_color "$YELLOW" "Instalando/Atualizando dependencias..."
			npm install
			;;
		4)
			print_color "$YELLOW" "Gerando build do projeto..."
			npm run build
			;;
		5)
			start_preview
			;;
		6)
			stop_process_from_pidfile_or_port "$PREVIEW_PID_FILE" "$PREVIEW_PORT" "Astro Preview"
			;;
		7)
			start_supabase_local
			;;
		8)
			stop_supabase_local
			;;
		9)
			restart_supabase_local
			;;
		10)
			reset_supabase_local
			;;
		11)
			show_supabase_status
			;;
		12)
			push_supabase_migrations
			;;
		13)
			if [ -f "$ASTRO_LOG" ]; then
				tail -n 40 "$ASTRO_LOG"
			else
				print_color "$RED" "Log do Astro Dev ainda nao existe."
			fi
			;;
		14)
			if [ -f "$PREVIEW_LOG" ]; then
				tail -n 40 "$PREVIEW_LOG"
			else
				print_color "$RED" "Log do Astro Preview ainda nao existe."
			fi
			;;
		15)
			if ensure_supabase_cli; then
				sync_local_env
			fi
			;;
		16)
			list_supabase_containers
			;;
		17)
			print_color "$YELLOW" "Rodando smoke tests do projeto..."
			npm run test:smoke
			;;
		0)
			print_line "Saindo do controle..."
			exit 0
			;;
		*)
			print_color "$RED" "Opcao invalida!"
			;;
	esac

	pause_for_user
done
