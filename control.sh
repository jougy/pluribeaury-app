#!/usr/bin/env bash

set -u

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT" || exit 1

ASTRO_PORT="${ASTRO_PORT:-4321}"
PREVIEW_PORT="${PREVIEW_PORT:-4322}"
ASTRO_LOG="$PROJECT_ROOT/astro_dev.log"
PREVIEW_LOG="$PROJECT_ROOT/astro_preview.log"
ASTRO_PID_FILE="$PROJECT_ROOT/.astro-dev.pid"
PREVIEW_PID_FILE="$PROJECT_ROOT/.astro-preview.pid"
SUPABASE_CONFIG="$PROJECT_ROOT/supabase/config.toml"
ENV_FILE="$PROJECT_ROOT/.env"

get_supabase_project_id() {
	if [ -f "$SUPABASE_CONFIG" ]; then
		grep -E '^project_id = ' "$SUPABASE_CONFIG" | head -n 1 | sed -E 's/^project_id = "(.*)"$/\1/'
	fi
}

SUPABASE_PROJECT_ID="${SUPABASE_PROJECT_ID:-$(get_supabase_project_id)}"
SUPABASE_KONG_CONTAINER="supabase_kong_${SUPABASE_PROJECT_ID}"
SUPABASE_DB_CONTAINER="supabase_db_${SUPABASE_PROJECT_ID}"
SUPABASE_STUDIO_CONTAINER="supabase_studio_${SUPABASE_PROJECT_ID}"

print_header() {
	clear
	echo -e "${BLUE}Pluribeauty Control Center${NC}"
	echo -e "${BLUE}Projeto:${NC} $PROJECT_ROOT"
	echo ""
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

is_port_listening() {
	local port="$1"
	if command_exists lsof && lsof -Pi :"$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
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
		lsof -t -i :"$port" 2>/dev/null | head -n 1
	fi
}

docker_available() {
	command_exists docker && docker ps >/dev/null 2>&1
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

sync_local_env() {
	if ! supabase_cli_available; then
		echo -e "${RED}Supabase CLI/config nao encontrados para sincronizar o .env.${NC}"
		return 1
	fi

	local env_dump
	env_dump="$(npx supabase status -o env 2>/dev/null)" || {
		echo -e "${RED}Nao consegui ler as variaveis do Supabase local.${NC}"
		return 1
	}

	local api_url anon_key publishable_key db_url studio_url
	api_url="$(printf '%s\n' "$env_dump" | grep '^API_URL=' | cut -d= -f2- | tr -d '"')"
	anon_key="$(printf '%s\n' "$env_dump" | grep '^ANON_KEY=' | cut -d= -f2- | tr -d '"')"
	publishable_key="$(printf '%s\n' "$env_dump" | grep '^PUBLISHABLE_KEY=' | cut -d= -f2- | tr -d '"')"
	db_url="$(printf '%s\n' "$env_dump" | grep '^DB_URL=' | cut -d= -f2- | tr -d '"')"
	studio_url="$(printf '%s\n' "$env_dump" | grep '^STUDIO_URL=' | cut -d= -f2- | tr -d '"')"

	cat >"$ENV_FILE" <<EOF
PUBLIC_SUPABASE_URL=$api_url
PUBLIC_SUPABASE_ANON_KEY=$anon_key
PUBLIC_SUPABASE_PUBLISHABLE_KEY=$publishable_key
SUPABASE_DB_URL=$db_url
SUPABASE_STUDIO_URL=$studio_url
EOF

	echo -e "${GREEN}.env sincronizado com o Supabase local.${NC}"
}

env_status() {
	if [ -f "$ENV_FILE" ]; then
		local public_url
		local anon_key
		public_url="$(grep -E '^PUBLIC_SUPABASE_URL=' "$ENV_FILE" | tail -n 1 | cut -d= -f2-)"
		anon_key="$(grep -E '^PUBLIC_SUPABASE_ANON_KEY=' "$ENV_FILE" | tail -n 1 | cut -d= -f2-)"

		if [ -n "$public_url" ]; then
			echo -e "Env Supabase: ${GREEN}$public_url${NC}"
		else
			echo -e "Env Supabase: ${YELLOW}PUBLIC_SUPABASE_URL ausente em .env${NC}"
		fi

		if [ -n "$anon_key" ]; then
			echo -e "Env Anon Key: ${GREEN}configurada${NC}"
		else
			echo -e "Env Anon Key: ${YELLOW}PUBLIC_SUPABASE_ANON_KEY ausente em .env${NC}"
		fi
	else
		echo -e "Env local: ${YELLOW}.env ainda nao existe${NC}"
	fi
}

check_status() {
	cleanup_pid_file "$ASTRO_PID_FILE"
	cleanup_pid_file "$PREVIEW_PID_FILE"

	echo -e "${BLUE}=== Status dos Servicos ===${NC}"

	if supabase_started; then
		echo -e "Supabase: ${GREEN}Ativo${NC} (API: http://127.0.0.1:54321 | Studio: http://127.0.0.1:54323 | DB: 127.0.0.1:54322)"
	else
		echo -e "Supabase: ${RED}Inativo${NC}"
	fi

	local astro_pid
	astro_pid="$(read_pid_file "$ASTRO_PID_FILE")"
	if pid_is_running "$astro_pid" || is_port_listening "$ASTRO_PORT"; then
		echo -e "Astro Dev: ${GREEN}Ativo${NC} (http://localhost:${ASTRO_PORT})"
	else
		echo -e "Astro Dev: ${RED}Inativo${NC}"
	fi

	local preview_pid
	preview_pid="$(read_pid_file "$PREVIEW_PID_FILE")"
	if pid_is_running "$preview_pid" || is_port_listening "$PREVIEW_PORT"; then
		echo -e "Astro Preview: ${GREEN}Ativo${NC} (http://localhost:${PREVIEW_PORT})"
	else
		echo -e "Astro Preview: ${RED}Inativo${NC}"
	fi

	env_status
	echo -e "${BLUE}===========================${NC}\n"
}

show_menu() {
	print_header
	check_status
	echo "Escolha uma opcao:"
	echo -e "${GREEN}--- Astro ---${NC}"
	echo " 1) Iniciar Astro Dev (background)"
	echo " 2) Parar Astro Dev"
	echo " 3) Instalar/Atualizar dependencias"
	echo " 4) Build do projeto"
	echo " 5) Iniciar Astro Preview (requer build)"
	echo " 6) Parar Astro Preview"
	echo -e "${YELLOW}--- Supabase Local (Docker) ---${NC}"
	echo " 7) Iniciar Supabase local"
	echo " 8) Parar Supabase local"
	echo " 9) Reiniciar Supabase local"
	echo "10) Resetar banco local Supabase"
	echo "11) Status detalhado do Supabase"
	echo "12) Aplicar migrations locais (db push)"
	echo -e "${BLUE}--- Utilitarios ---${NC}"
	echo "13) Ver ultimas linhas do log do Astro Dev"
	echo "14) Ver ultimas linhas do log do Preview"
	echo "15) Sincronizar .env com Supabase local"
	echo "16) Listar containers do Supabase local"
	echo "17) Rodar smoke tests do projeto"
	echo " 0) Sair"
	echo ""
}

start_astro_dev() {
	if pid_is_running "$(read_pid_file "$ASTRO_PID_FILE")" || is_port_listening "$ASTRO_PORT"; then
		echo -e "${YELLOW}Astro Dev ja parece estar rodando na porta ${ASTRO_PORT}.${NC}"
		return
	fi

	echo -e "${YELLOW}Iniciando Astro Dev em background...${NC}"
	nohup npm run dev -- --host 0.0.0.0 --port "$ASTRO_PORT" >"$ASTRO_LOG" 2>&1 &
	echo $! >"$ASTRO_PID_FILE"
	sleep 2

	if pid_is_running "$(read_pid_file "$ASTRO_PID_FILE")"; then
		echo -e "${GREEN}Astro Dev iniciado.${NC} Logs em ${ASTRO_LOG}"
	else
		echo -e "${RED}Falha ao iniciar Astro Dev.${NC} Veja ${ASTRO_LOG}"
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
		echo -e "${YELLOW}Parando ${label}...${NC}"
		kill "$pid" >/dev/null 2>&1 || true
		sleep 1
		if pid_is_running "$pid"; then
			kill -9 "$pid" >/dev/null 2>&1 || true
		fi
		rm -f "$pid_file"
		echo -e "${GREEN}${label} encerrado.${NC}"
	else
		echo -e "${RED}${label} nao parece estar rodando.${NC}"
	fi
}

start_preview() {
	if pid_is_running "$(read_pid_file "$PREVIEW_PID_FILE")" || is_port_listening "$PREVIEW_PORT"; then
		echo -e "${YELLOW}Astro Preview ja parece estar rodando na porta ${PREVIEW_PORT}.${NC}"
		return
	fi

	if [ ! -d "$PROJECT_ROOT/dist" ]; then
		echo -e "${YELLOW}Nao encontrei build em dist/. Vou gerar antes de abrir o preview.${NC}"
		npm run build || return
	fi

	echo -e "${YELLOW}Iniciando Astro Preview em background...${NC}"
	nohup npm run preview -- --host 0.0.0.0 --port "$PREVIEW_PORT" >"$PREVIEW_LOG" 2>&1 &
	echo $! >"$PREVIEW_PID_FILE"
	sleep 2

	if pid_is_running "$(read_pid_file "$PREVIEW_PID_FILE")"; then
		echo -e "${GREEN}Astro Preview iniciado.${NC} Logs em ${PREVIEW_LOG}"
	else
		echo -e "${RED}Falha ao iniciar Astro Preview.${NC} Veja ${PREVIEW_LOG}"
	fi
}

ensure_supabase_cli() {
	if ! supabase_cli_available; then
		echo -e "${RED}Supabase CLI/config nao encontrados. Rode 'npx supabase init' neste projeto.${NC}"
		return 1
	fi

	if ! docker_available; then
		echo -e "${RED}Docker nao esta acessivel para o usuario atual.${NC}"
		return 1
	fi

	return 0
}

list_supabase_containers() {
	if ! docker_available; then
		echo -e "${RED}Docker nao esta acessivel.${NC}"
		return 1
	fi

	docker ps --format '{{.Names}}\t{{.Status}}\t{{.Ports}}' | grep "supabase_.*_${SUPABASE_PROJECT_ID}" || echo "Nenhum container do Supabase local em execucao."
}

pause_for_user() {
	echo ""
	read -r -p "Pressione [Enter] para continuar..."
}

while true; do
	show_menu
	read -r -p "Opcao: " opt
	echo ""

	case "$opt" in
		1)
			start_astro_dev
			;;
		2)
			stop_process_from_pidfile_or_port "$ASTRO_PID_FILE" "$ASTRO_PORT" "Astro Dev"
			;;
		3)
			echo -e "${YELLOW}Instalando/Atualizando dependencias...${NC}"
			npm install
			;;
		4)
			echo -e "${YELLOW}Gerando build do projeto...${NC}"
			npm run build
			;;
		5)
			start_preview
			;;
		6)
			stop_process_from_pidfile_or_port "$PREVIEW_PID_FILE" "$PREVIEW_PORT" "Astro Preview"
			;;
		7)
			if ensure_supabase_cli; then
				echo -e "${YELLOW}Iniciando Supabase local...${NC}"
				npx supabase start && sync_local_env
			fi
			;;
		8)
			if ensure_supabase_cli; then
				echo -e "${YELLOW}Parando Supabase local...${NC}"
				npx supabase stop
			fi
			;;
		9)
			if ensure_supabase_cli; then
				echo -e "${YELLOW}Reiniciando Supabase local...${NC}"
				npx supabase stop
				npx supabase start && sync_local_env
			fi
			;;
		10)
			if ensure_supabase_cli; then
				echo -e "${RED}Isso vai apagar os dados locais do Supabase. Confirmar? (y/N)${NC}"
				read -r -p "Confirmar: " confirm
				if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
					npx supabase db reset && sync_local_env
				else
					echo "Operacao cancelada."
				fi
			fi
			;;
		11)
			if ensure_supabase_cli; then
				npx supabase status
			fi
			;;
		12)
			if ensure_supabase_cli; then
				echo -e "${YELLOW}Aplicando migrations locais...${NC}"
				npx supabase db push
			fi
			;;
		13)
			if [ -f "$ASTRO_LOG" ]; then
				tail -n 40 "$ASTRO_LOG"
			else
				echo -e "${RED}Log do Astro Dev ainda nao existe.${NC}"
			fi
			;;
		14)
			if [ -f "$PREVIEW_LOG" ]; then
				tail -n 40 "$PREVIEW_LOG"
			else
				echo -e "${RED}Log do Astro Preview ainda nao existe.${NC}"
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
			echo -e "${YELLOW}Rodando smoke tests do projeto...${NC}"
			npm run test:smoke
			;;
		0)
			echo "Saindo do controle..."
			exit 0
			;;
		*)
			echo -e "${RED}Opcao invalida!${NC}"
			;;
	esac

	pause_for_user
done
