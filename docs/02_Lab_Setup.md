# 02 - Lab Setup

## Netzwerkuebersicht

| System | Zweck | IP/Port |
|---|---|---|
| Windows 11 Host | Zielsystem, Wazuh Agent, Docker Host | 192.168.56.1, 192.168.0.231 |
| Wazuh OVA VM | Manager, Indexer, Dashboard | 192.168.0.214, 192.168.56.102 |
| Kali Linux VM | Angriffssimulation im Lab | Host-only-Netz |
| Shuffle SOAR | Workflow-Automatisierung | 127.0.0.1:3001, extern 192.168.56.1:3002 |

## Wazuh-Agent auf Windows pruefen

```powershell
Get-Service WazuhSvc
Select-String -Path "C:\Program Files (x86)\ossec-agent\ossec.conf" -Pattern "<address>"
Restart-Service WazuhSvc
```

## Wazuh-Agent auf dem Manager pruefen

```bash
sudo /var/ossec/bin/agent_control -l
sudo systemctl status wazuh-manager.service --no-pager
```

## Shuffle starten

Im Shuffle-Verzeichnis:

```powershell
docker compose up -d
docker ps
```

## Portproxy fuer Shuffle

```powershell
netsh interface portproxy add v4tov4 listenaddress=192.168.56.1 listenport=3002 connectaddress=127.0.0.1 connectport=3001
netsh interface portproxy show all
```

Test von Wazuh aus:

```bash
curl --connect-timeout 5 -I http://192.168.56.1:3002
```
