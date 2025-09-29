# 🐧 Script de Configuração do Sistema Debian 12

![Debian](https://img.shields.io/badge/Debian-12-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-1.0.0-green?style=for-the-badge)

> 🚀 Script automatizado para configuração inicial de sistemas Debian 12, incluindo atualização do sistema, configuração de hora, hostname e IP estático.

## ✨ Funcionalidades

- 🔄 **Atualização Completa do Sistema**: `apt update`, `upgrade`, `dist-upgrade`, `autoremove` e `autoclean`
- ⏰ **Configuração de Hora/Timezone**: Timezones brasileiros e sincronização NTP automática
- 🏷️ **Configuração de Hostname**: Alteração segura do nome do sistema
- 🌐 **Configuração de IP Estático**: Interface amigável para configuração de rede
- 📊 **Status Completo do Sistema**: Visualização detalhada de informações do sistema
- 📝 **Sistema de Logs**: Registro completo de todas as operações
- 🎨 **Interface Colorida**: Output com cores para melhor experiência

## 🛠️ Pré-requisitos

- Sistema Debian 12 (Bookworm)
- Privilégios de root (sudo)
- Conexão com a internet (para atualizações)

## 📥 Instalação

### Método 1: Clone do Repositório
```bash
git clone https://github.com/seu-usuario/debian12-config-script.git
cd debian12-config-script
chmod +x debian12_config.sh
```

### Método 2: Download Direto
```bash
wget https://raw.githubusercontent.com/seu-usuario/debian12-config-script/main/debian12_config.sh
chmod +x debian12_config.sh
```

## 🚀 Como Usar

### Execução Básica
```bash
sudo ./debian12_config.sh
```

### Menu Interativo
O script apresenta um menu com as seguintes opções:

1. **Atualizar sistema** - Atualização completa de pacotes
2. **Configurar hora/timezone** - Configuração de fuso horário
3. **Configurar hostname** - Alteração do nome do sistema
4. **Configurar IP estático** - Configuração de rede estática
5. **Executar todas as operações** - Execução completa
6. **Ver status completo do sistema** - Informações detalhadas
7. **Sair** - Encerrar o script

## 📋 Funcionalidades Detalhadas

### 🔄 Atualização do Sistema
- Atualiza lista de pacotes (`apt update`)
- Faz upgrade dos pacotes (`apt upgrade`)
- Executa dist-upgrade (`apt dist-upgrade`)
- Remove pacotes desnecessários (`apt autoremove`)
- Limpa cache (`apt autoclean`)
- Verifica integridade dos pacotes
- **Detecta necessidade de reinicialização**

### ⏰ Configuração de Hora/Timezone
Timezones brasileiros disponíveis:
- `America/Sao_Paulo` (Brasília, São Paulo, Rio de Janeiro)
- `America/Manaus` (Manaus, Amazonas)
- `America/Fortaleza` (Fortaleza, Ceará)
- `America/Recife` (Recife, Pernambuco)
- `America/Bahia` (Salvador, Bahia)

**Recursos:**
- Sincronização NTP automática
- Instalação do chrony se necessário
- Fallback inteligente para diferentes serviços de tempo

### 🏷️ Configuração de Hostname
- Validação de formato do hostname
- Atualização automática do `/etc/hosts`
- Preservação da configuração existente

### 🌐 Configuração de IP Estático
- **Detecção automática** de interfaces de rede
- **Validação completa** de IP, gateway e DNS
- **Backup automático** da configuração atual
- **Testes de conectividade** após aplicação
- **Recuperação automática** em caso de erro
- Suporte ao netplan (padrão Debian 12)

### 📊 Status Completo do Sistema
Informações exibidas:
- **Sistema**: Hostname, versão, kernel, arquitetura, uptime
- **Data/Hora**: Timezone, sincronização NTP
- **Rede**: Interfaces, IPs, gateway, DNS
- **Recursos**: Memória, disco, load average
- **Serviços**: Status de serviços importantes
- **Pacotes**: Atualizações disponíveis, pacotes importantes

## 📁 Arquivos Modificados

O script pode modificar os seguintes arquivos:
- `/etc/hostname` - Nome do sistema
- `/etc/hosts` - Mapeamento de nomes
- `/etc/netplan/*.yaml` - Configuração de rede
- `/var/log/debian12_config.log` - Log das operações

## 📝 Logs

Todas as operações são registradas em `/var/log/debian12_config.log` com timestamp completo.

## 🔒 Segurança

- ✅ Verificação de privilégios de root
- ✅ Backup automático antes de alterações
- ✅ Validação rigorosa de entrada
- ✅ Tratamento de erros robusto
- ✅ Recuperação automática em falhas

## 💡 Exemplos de Uso

### Configuração Completa Automatizada
```bash
sudo ./debian12_config.sh
# Escolher opção 5 (Executar todas as operações)
```

### Apenas Verificar Status do Sistema
```bash
sudo ./debian12_config.sh
# Escolher opção 6 (Ver status completo do sistema)
```

### Configurar IP Estático
```bash
sudo ./debian12_config.sh
# Escolher opção 4 (Configurar IP estático)
# Exemplo de configuração:
# Interface: eth0
# IP: 192.168.1.100/24
# Gateway: 192.168.1.1
# DNS: 8.8.8.8, 8.8.4.4
```

## 🐛 Troubleshooting

### Script não executa
```bash
# Verificar permissões
ls -la debian12_config.sh
chmod +x debian12_config.sh

# Executar com sudo
sudo ./debian12_config.sh
```

### Erro de sintaxe
```bash
# NÃO usar sh, usar bash diretamente
sudo ./debian12_config.sh  # ✅ Correto
sudo sh ./debian12_config.sh  # ❌ Incorreto
```

### Problemas de rede após configurar IP
```bash
# Verificar configuração netplan
sudo netplan --debug apply

# Restaurar backup se necessário
sudo cp /etc/netplan/backup-*.yaml /etc/netplan/01-static-config.yaml
sudo netplan apply
```

### Problemas de timezone
```bash
# Listar timezones disponíveis
timedatectl list-timezones | grep America

# Configurar manualmente
sudo timedatectl set-timezone America/Sao_Paulo
```

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🏆 Características Técnicas

- **Linguagem**: Bash 4+
- **Compatibilidade**: Debian 12 (Bookworm)
- **Dependências**: Ferramentas padrão do sistema
- **Tamanho**: ~15KB
- **Tempo de execução**: 2-10 minutos (dependendo das operações)

## 📞 Suporte

Se você encontrar problemas ou tiver sugestões:

- 🐛 [Reportar Bug](https://github.com/seu-usuario/debian12-config-script/issues)
- 💡 [Solicitar Feature](https://github.com/seu-usuario/debian12-config-script/issues)
- 📧 [Contato](mailto:seu-email@exemplo.com)

## ⭐ Se este projeto foi útil, considere dar uma estrela!

---

<div align="center">

**Desenvolvido com ❤️ para a comunidade Debian**

[⬆ Voltar ao topo](#-script-de-configuração-do-sistema-debian-12)

</div>