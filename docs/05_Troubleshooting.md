# 05 - Troubleshooting

| Problem | Ursache | Loesung |
|---|---|---|
| Alte Wazuh-IP nicht erreichbar | Agent zeigte auf alte Adresse `172.31.182.124` | Aktuelle Wazuh-IP mit `hostname -I` pruefen und Agent-Konfiguration anpassen |
| Windows-Agent nicht verbunden | Falsche Manager-Adresse in `ossec.conf` | Adresse auf `192.168.0.214` setzen und `WazuhSvc` neu starten |
| Shuffle von Wazuh nicht erreichbar | Docker-Port nur lokal auf Windows erreichbar | Portproxy `192.168.56.1:3002 -> 127.0.0.1:3001` einrichten |
| Docker Desktop nicht gestartet | Shuffle-Container laufen nicht | Docker Desktop starten und `docker compose up -d` ausfuehren |
| Dashboard-Loginproblem | Passwort nicht bekannt/ungueltig | Admin-Passwort mit Wazuh-Passworttool zuruecksetzen |
| Keine Alerts sichtbar | Zeitfilter oder Agent-Status falsch | Zeitbereich im Dashboard erweitern, Agent-Status und Windows Events pruefen |

## Wichtige Diagnosebefehle

### Windows

```powershell
Get-Service WazuhSvc
Restart-Service WazuhSvc
ipconfig
netsh interface portproxy show all
```

### Wazuh-VM

```bash
hostname -I
ip a
sudo /var/ossec/bin/agent_control -l
sudo systemctl status wazuh-manager.service --no-pager
```

### Shuffle/Docker

```powershell
docker ps
docker compose up -d
curl http://127.0.0.1:3001
```
