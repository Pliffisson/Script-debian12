#!/bin/bash

# Script de Configuração do Sistema Debian 12
# Autor: Sistema Automatizado
# Data: $(date)
# Descrição: Script para atualização do sistema e configuração de hora, hostname e IP

set -e  # Sair em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Arquivo de log
LOG_FILE="/var/log/debian12_config.log"

# Função para logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Função para exibir mensagens coloridas
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
    log "$message"
}

# Verificar se está executando como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_message "$RED" "Este script deve ser executado como root (sudo)"
        exit 1
    fi
}

# Função para atualizar o sistema
update_system() {
    print_message "$BLUE" "=== INICIANDO ATUALIZAÇÃO DO SISTEMA ==="
    
    print_message "$YELLOW" "Atualizando lista de pacotes..."
    if apt update -y; then
        print_message "$GREEN" "Lista de pacotes atualizada com sucesso"
    else
        print_message "$RED" "Erro ao atualizar lista de pacotes"
        return 1
    fi
    
    print_message "$YELLOW" "Fazendo upgrade dos pacotes instalados..."
    if apt upgrade -y; then
        print_message "$GREEN" "Upgrade dos pacotes concluído"
    else
        print_message "$RED" "Erro durante o upgrade dos pacotes"
        return 1
    fi
    
    print_message "$YELLOW" "Fazendo dist-upgrade..."
    if apt dist-upgrade -y; then
        print_message "$GREEN" "Dist-upgrade concluído"
    else
        print_message "$YELLOW" "Aviso: Problemas durante o dist-upgrade"
    fi
    
    print_message "$YELLOW" "Removendo pacotes desnecessários..."
    if apt autoremove -y; then
        print_message "$GREEN" "Pacotes desnecessários removidos"
    else
        print_message "$YELLOW" "Aviso: Problemas ao remover pacotes desnecessários"
    fi
    
    print_message "$YELLOW" "Limpando cache de pacotes..."
    if apt autoclean; then
        print_message "$GREEN" "Cache de pacotes limpo"
    else
        print_message "$YELLOW" "Aviso: Problemas ao limpar cache"
    fi
    
    # Verificar se há pacotes quebrados
    print_message "$YELLOW" "Verificando integridade dos pacotes..."
    if dpkg --configure -a; then
        print_message "$GREEN" "Integridade dos pacotes verificada"
    else
        print_message "$YELLOW" "Aviso: Alguns pacotes podem precisar de configuração manual"
    fi
    
    # Verificar se é necessário reiniciar
    if [[ -f /var/run/reboot-required ]]; then
        print_message "$YELLOW" "⚠️  ATENÇÃO: Reinicialização necessária após as atualizações!"
        print_message "$YELLOW" "Execute 'sudo reboot' quando possível."
    fi
    
    print_message "$GREEN" "Atualização do sistema concluída!"
}

# Função para configurar timezone/hora
configure_time() {
    print_message "$BLUE" "=== CONFIGURANDO HORA E TIMEZONE ==="
    
    echo "Timezones disponíveis no Brasil:"
    echo "1) America/Sao_Paulo (Brasília, São Paulo, Rio de Janeiro)"
    echo "2) America/Manaus (Manaus, Amazonas)"
    echo "3) America/Fortaleza (Fortaleza, Ceará)"
    echo "4) America/Recife (Recife, Pernambuco)"
    echo "5) America/Bahia (Salvador, Bahia)"
    echo "6) Manter timezone atual"
    
    read -p "Escolha uma opção (1-6): " timezone_choice
    
    case $timezone_choice in
        1)
            timedatectl set-timezone America/Sao_Paulo
            print_message "$GREEN" "Timezone configurado para America/Sao_Paulo"
            ;;
        2)
            timedatectl set-timezone America/Manaus
            print_message "$GREEN" "Timezone configurado para America/Manaus"
            ;;
        3)
            timedatectl set-timezone America/Fortaleza
            print_message "$GREEN" "Timezone configurado para America/Fortaleza"
            ;;
        4)
            timedatectl set-timezone America/Recife
            print_message "$GREEN" "Timezone configurado para America/Recife"
            ;;
        5)
            timedatectl set-timezone America/Bahia
            print_message "$GREEN" "Timezone configurado para America/Bahia"
            ;;
        6)
            print_message "$YELLOW" "Mantendo timezone atual"
            ;;
        *)
            print_message "$RED" "Opção inválida. Mantendo timezone atual."
            ;;
    esac
    
    # Sincronizar com NTP
    print_message "$YELLOW" "Configurando sincronização de tempo..."
    
    # Tentar habilitar NTP via timedatectl
    if timedatectl set-ntp true 2>/dev/null; then
        print_message "$GREEN" "Sincronização NTP habilitada via systemd-timesyncd"
    else
        print_message "$YELLOW" "NTP via systemd não suportado, configurando chrony..."
        
        # Instalar e configurar chrony
        if ! command -v chrony &> /dev/null; then
            print_message "$YELLOW" "Instalando chrony para sincronização de tempo..."
            apt install -y chrony
        fi
        
        # Configurar chrony
        systemctl enable chrony 2>/dev/null || true
        systemctl start chrony 2>/dev/null || true
        
        # Verificar se chrony está funcionando
        if systemctl is-active --quiet chrony; then
            print_message "$GREEN" "Chrony configurado e ativo"
        else
            print_message "$YELLOW" "Aviso: Não foi possível configurar sincronização automática de tempo"
        fi
    fi
    
    # Forçar sincronização manual se possível
    if command -v chrony &> /dev/null; then
        print_message "$YELLOW" "Forçando sincronização de tempo..."
        chrony sources 2>/dev/null || true
    fi
    
    print_message "$GREEN" "Configuração de hora concluída!"
    print_message "$BLUE" "Hora atual: $(date)"
}

# Função para configurar hostname
configure_hostname() {
    print_message "$BLUE" "=== CONFIGURANDO HOSTNAME ==="
    
    current_hostname=$(hostname)
    print_message "$YELLOW" "Hostname atual: $current_hostname"
    
    read -p "Digite o novo hostname (ou pressione Enter para manter o atual): " new_hostname
    
    if [[ -n "$new_hostname" ]]; then
        # Validar hostname
        if [[ ! "$new_hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
            print_message "$RED" "Hostname inválido. Deve conter apenas letras, números e hífens."
            return 1
        fi
        
        # Configurar hostname
        hostnamectl set-hostname "$new_hostname"
        
        # Atualizar /etc/hosts
        sed -i "s/127.0.1.1.*/127.0.1.1\t$new_hostname/" /etc/hosts
        
        # Se não existir entrada 127.0.1.1, adicionar
        if ! grep -q "127.0.1.1" /etc/hosts; then
            echo "127.0.1.1	$new_hostname" >> /etc/hosts
        fi
        
        print_message "$GREEN" "Hostname configurado para: $new_hostname"
    else
        print_message "$YELLOW" "Mantendo hostname atual: $current_hostname"
    fi
}

# Função para configurar IP estático
configure_static_ip() {
    print_message "$BLUE" "=== CONFIGURANDO IP ESTÁTICO ==="
    
    # Listar interfaces de rede
    print_message "$YELLOW" "Interfaces de rede disponíveis:"
    ip link show | grep -E "^[0-9]+:" | awk -F': ' '{print $2}' | grep -v lo
    
    read -p "Digite o nome da interface de rede (ex: eth0, enp0s3): " interface
    
    # Verificar se a interface existe
    if ! ip link show "$interface" &> /dev/null; then
        print_message "$RED" "Interface $interface não encontrada!"
        return 1
    fi
    
    # Obter configuração atual
    current_ip=$(ip addr show "$interface" | grep "inet " | awk '{print $2}' | head -1)
    current_gateway=$(ip route | grep default | awk '{print $3}' | head -1)
    
    print_message "$YELLOW" "Configuração atual da interface $interface:"
    print_message "$YELLOW" "IP: ${current_ip:-"Não configurado (DHCP)"}"
    print_message "$YELLOW" "Gateway: ${current_gateway:-"Não configurado"}"
    
    # Verificar se está usando DHCP
    if systemctl is-active --quiet dhcpcd 2>/dev/null || pgrep -f "dhclient.*$interface" &>/dev/null; then
        print_message "$YELLOW" "Interface atualmente configurada via DHCP"
    fi
    
    echo
    echo "Escolha uma opção:"
    echo "1) Configurar IP estático"
    echo "2) Manter configuração atual (DHCP)"
    
    read -p "Opção (1-2): " ip_choice
    
    if [[ "$ip_choice" == "1" ]]; then
        read -p "Digite o IP estático (ex: 192.168.1.100/24): " static_ip
        read -p "Digite o gateway (ex: 192.168.1.1): " gateway
        read -p "Digite o DNS primário (ex: 8.8.8.8): " dns1
        read -p "Digite o DNS secundário (ex: 8.8.4.4, ou Enter para pular): " dns2
        
        # Validar formato do IP
        if [[ ! "$static_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
            print_message "$RED" "Formato de IP inválido. Use o formato: 192.168.1.100/24"
            return 1
        fi
        
        # Validar formato do gateway
        if [[ ! "$gateway" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            print_message "$RED" "Formato de gateway inválido. Use o formato: 192.168.1.1"
            return 1
        fi
        
        # Validar DNS
        if [[ ! "$dns1" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            print_message "$RED" "Formato de DNS primário inválido. Use o formato: 8.8.8.8"
            return 1
        fi
        
        if [[ -n "$dns2" && ! "$dns2" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            print_message "$RED" "Formato de DNS secundário inválido. Use o formato: 8.8.4.4"
            return 1
        fi
        
        # Backup da configuração atual
        cp /etc/netplan/*.yaml /etc/netplan/backup-$(date +%Y%m%d-%H%M%S).yaml 2>/dev/null || true
        
        # Criar configuração netplan
        cat > /etc/netplan/01-static-config.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $interface:
      dhcp4: false
      addresses:
        - $static_ip
      gateway4: $gateway
      nameservers:
        addresses:
          - $dns1
EOF
        
        # Adicionar DNS secundário se fornecido
        if [[ -n "$dns2" ]]; then
            echo "          - $dns2" >> /etc/netplan/01-static-config.yaml
        fi
        
        # Aplicar configuração
        print_message "$YELLOW" "Aplicando configuração de rede..."
        if netplan apply; then
            print_message "$GREEN" "Configuração de rede aplicada com sucesso!"
            
            # Aguardar um momento para a rede se estabilizar
            sleep 3
            
            # Verificar conectividade
            print_message "$YELLOW" "Testando conectividade..."
            if ping -c 1 "$gateway" &>/dev/null; then
                print_message "$GREEN" "✓ Conectividade com gateway OK"
            else
                print_message "$YELLOW" "⚠ Aviso: Não foi possível pingar o gateway"
            fi
            
            if ping -c 1 "$dns1" &>/dev/null; then
                print_message "$GREEN" "✓ Conectividade com DNS OK"
            else
                print_message "$YELLOW" "⚠ Aviso: Não foi possível pingar o DNS"
            fi
            
        else
            print_message "$RED" "Erro ao aplicar configuração de rede!"
            print_message "$YELLOW" "Tentando restaurar configuração anterior..."
            
            # Tentar restaurar backup mais recente
            latest_backup=$(ls -t /etc/netplan/backup-*.yaml 2>/dev/null | head -1)
            if [[ -n "$latest_backup" ]]; then
                cp "$latest_backup" /etc/netplan/01-static-config.yaml
                netplan apply
                print_message "$YELLOW" "Configuração anterior restaurada"
            fi
            return 1
        fi
        
        print_message "$GREEN" "IP estático configurado com sucesso!"
        print_message "$BLUE" "Nova configuração:"
        print_message "$BLUE" "IP: $static_ip"
        print_message "$BLUE" "Gateway: $gateway"
        print_message "$BLUE" "DNS: $dns1 ${dns2:+$dns2}"
        
    else
        print_message "$YELLOW" "Mantendo configuração atual (DHCP)"
    fi
}

# Função para exibir status completo do sistema
show_system_status() {
    print_message "$BLUE" "=== STATUS COMPLETO DO SISTEMA ==="
    
    # Informações básicas do sistema
    print_message "$YELLOW" "--- INFORMAÇÕES DO SISTEMA ---"
    print_message "$GREEN" "Hostname: $(hostname)"
    print_message "$GREEN" "Sistema: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Debian $(cat /etc/debian_version 2>/dev/null || echo 'N/A')")"
    print_message "$GREEN" "Kernel: $(uname -r)"
    print_message "$GREEN" "Arquitetura: $(uname -m)"
    print_message "$GREEN" "Uptime: $(uptime -p 2>/dev/null || uptime)"
    
    # Informações de data/hora
    print_message "$YELLOW" "--- DATA E HORA ---"
    print_message "$GREEN" "Data/Hora atual: $(date)"
    print_message "$GREEN" "Timezone: $(timedatectl show --property=Timezone --value 2>/dev/null || echo 'N/A')"
    
    # Status do NTP/Sincronização
    if command -v timedatectl &> /dev/null; then
        ntp_status=$(timedatectl show --property=NTP --value 2>/dev/null || echo "N/A")
        print_message "$GREEN" "Sincronização NTP: $ntp_status"
    fi
    
    if systemctl is-active --quiet systemd-timesyncd 2>/dev/null; then
        print_message "$GREEN" "systemd-timesyncd: Ativo"
    elif systemctl is-active --quiet chrony 2>/dev/null; then
        print_message "$GREEN" "chrony: Ativo"
    else
        print_message "$YELLOW" "Sincronização de tempo: Não configurada"
    fi
    
    # Configuração de rede
    print_message "$YELLOW" "--- CONFIGURAÇÃO DE REDE ---"
    
    # Interfaces de rede
    for interface in $(ip link show | grep -E "^[0-9]+:" | awk -F': ' '{print $2}' | grep -v lo); do
        print_message "$GREEN" "Interface: $interface"
        
        # Status da interface
        status=$(ip link show "$interface" | grep -o "state [A-Z]*" | cut -d' ' -f2)
        print_message "$GREEN" "  Status: $status"
        
        # Endereços IP
        ips=$(ip addr show "$interface" | grep "inet " | awk '{print $2}')
        if [[ -n "$ips" ]]; then
            while IFS= read -r ip; do
                print_message "$GREEN" "  IP: $ip"
            done <<< "$ips"
        else
            print_message "$YELLOW" "  IP: Não configurado"
        fi
        
        # MAC Address
        mac=$(ip link show "$interface" | grep "link/ether" | awk '{print $2}')
        if [[ -n "$mac" ]]; then
            print_message "$GREEN" "  MAC: $mac"
        fi
        echo
    done
    
    # Gateway padrão
    default_gateway=$(ip route | grep default | awk '{print $3}' | head -1)
    if [[ -n "$default_gateway" ]]; then
        print_message "$GREEN" "Gateway padrão: $default_gateway"
    else
        print_message "$YELLOW" "Gateway padrão: Não configurado"
    fi
    
    # Servidores DNS
    print_message "$GREEN" "Servidores DNS:"
    if [[ -f /etc/resolv.conf ]]; then
        grep "nameserver" /etc/resolv.conf | while read -r line; do
            dns=$(echo "$line" | awk '{print $2}')
            print_message "$GREEN" "  $dns"
        done
    fi
    
    # Uso de recursos
    print_message "$YELLOW" "--- USO DE RECURSOS ---"
    
    # Memória
    if command -v free &> /dev/null; then
        mem_info=$(free -h | grep "Mem:")
        mem_total=$(echo "$mem_info" | awk '{print $2}')
        mem_used=$(echo "$mem_info" | awk '{print $3}')
        mem_free=$(echo "$mem_info" | awk '{print $4}')
        print_message "$GREEN" "Memória Total: $mem_total | Usada: $mem_used | Livre: $mem_free"
    fi
    
    # Disco
    if command -v df &> /dev/null; then
        print_message "$GREEN" "Uso do disco (/):"
        df -h / | tail -1 | awk '{print "  Tamanho: " $2 " | Usado: " $3 " | Disponível: " $4 " | Uso: " $5}' | while read -r line; do
            print_message "$GREEN" "$line"
        done
    fi
    
    # Load average
    if [[ -f /proc/loadavg ]]; then
        load=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
        print_message "$GREEN" "Load average (1m 5m 15m): $load"
    fi
    
    # Serviços importantes
    print_message "$YELLOW" "--- STATUS DE SERVIÇOS ---"
    
    services=("ssh" "networking" "systemd-resolved" "cron")
    for service in "${services[@]}"; do
        if systemctl is-enabled "$service" &>/dev/null; then
            if systemctl is-active --quiet "$service"; then
                print_message "$GREEN" "$service: Ativo e habilitado"
            else
                print_message "$YELLOW" "$service: Habilitado mas inativo"
            fi
        else
            if systemctl is-active --quiet "$service"; then
                print_message "$YELLOW" "$service: Ativo mas não habilitado"
            else
                print_message "$RED" "$service: Inativo e não habilitado"
            fi
        fi
    done
    
    # Últimas atualizações
    print_message "$YELLOW" "--- INFORMAÇÕES DE PACOTES ---"
    if [[ -f /var/log/apt/history.log ]]; then
        last_update=$(grep "Start-Date" /var/log/apt/history.log | tail -1 | cut -d' ' -f2-3)
        if [[ -n "$last_update" ]]; then
            print_message "$GREEN" "Última atualização: $last_update"
        fi
    fi
    
    # Pacotes que podem ser atualizados
    if command -v apt &> /dev/null; then
        print_message "$YELLOW" "Verificando atualizações disponíveis..."
        apt list --upgradable 2>/dev/null > /tmp/upgradable_packages.txt
        upgradable=$(wc -l < /tmp/upgradable_packages.txt)
        if [[ $upgradable -gt 1 ]]; then
            print_message "$YELLOW" "Pacotes que podem ser atualizados: $((upgradable - 1))"
            
            # Mostrar alguns pacotes importantes que podem ser atualizados
            important_packages=$(grep -E "(kernel|linux-|systemd|openssh|nginx|apache)" /tmp/upgradable_packages.txt | head -3)
            if [[ -n "$important_packages" ]]; then
                print_message "$YELLOW" "Pacotes importantes para atualizar:"
                echo "$important_packages" | while read -r line; do
                    package=$(echo "$line" | cut -d'/' -f1)
                    print_message "$YELLOW" "  - $package"
                done
            fi
        else
            print_message "$GREEN" "Sistema atualizado - nenhum pacote pendente"
        fi
        rm -f /tmp/upgradable_packages.txt
    fi
    
    print_message "$BLUE" "================================"
}

# Função para exibir resumo final
show_summary() {
    print_message "$BLUE" "=== RESUMO DA CONFIGURAÇÃO ==="
    print_message "$GREEN" "Hostname: $(hostname)"
    print_message "$GREEN" "Data/Hora: $(date)"
    print_message "$GREEN" "Timezone: $(timedatectl show --property=Timezone --value)"
    print_message "$GREEN" "Configuração de rede:"
    ip addr show | grep -E "(inet |^[0-9]+:)" | grep -v "127.0.0.1"
    print_message "$BLUE" "================================"
}

# Função principal
main() {
    print_message "$GREEN" "=== SCRIPT DE CONFIGURAÇÃO DEBIAN 12 ==="
    print_message "$BLUE" "Iniciando configuração do sistema..."
    
    # Verificar privilégios
    check_root
    
    # Criar arquivo de log
    touch "$LOG_FILE"
    log "=== INÍCIO DA EXECUÇÃO DO SCRIPT ==="
    
    # Menu principal
    echo
    echo "Selecione as operações que deseja realizar:"
    echo "1) Atualizar sistema"
    echo "2) Configurar hora/timezone"
    echo "3) Configurar hostname"
    echo "4) Configurar IP estático"
    echo "5) Executar todas as operações"
    echo "6) Ver status completo do sistema"
    echo "7) Sair"
    
    read -p "Digite sua escolha (1-7): " choice
    
    case $choice in
        1)
            update_system
            ;;
        2)
            configure_time
            ;;
        3)
            configure_hostname
            ;;
        4)
            configure_static_ip
            ;;
        5)
            update_system
            configure_time
            configure_hostname
            configure_static_ip
            ;;
        6)
            show_system_status
            ;;
        7)
            print_message "$YELLOW" "Saindo..."
            exit 0
            ;;
        *)
            print_message "$RED" "Opção inválida!"
            exit 1
            ;;
    esac
    
    # Mostrar status apenas se não for a opção de status completo
    if [[ "$choice" != "6" ]]; then
        show_summary
    fi
    
    log "=== FIM DA EXECUÇÃO DO SCRIPT ==="
    print_message "$GREEN" "Script executado com sucesso! Log salvo em: $LOG_FILE"
}

# Executar função principal
main "$@"