# 00 - Installation und Grundaufbau: Wazuh, Windows-Agent, Kali und Shuffle SOAR

Diese Datei dokumentiert den technischen Aufbau des Projekts von der Installation bzw. Bereitstellung der Systeme bis zur Angriffssimulation. Die Angaben basieren auf den Projektmaterialien, Screenshots und verwendeten Terminalbefehlen.

## 1. Laborziel

Ziel war der Aufbau einer lokalen SIEM-SOAR-Testumgebung:

```text
Kali Linux VM -> Windows 11 Host mit Wazuh Agent -> Wazuh OVA VM -> Shuffle SOAR Workflow
```

Der Testangriff sollte bewusst nur in einer eigenen Laborumgebung stattfinden. Es wurde kein fremdes System angegriffen.

## 2. Eingesetzte Systeme

| Komponente | Rolle im Projekt | Hinweise |
|---|---|---|
| Windows 11 Host | Zielsystem, Docker-Host, Wazuh-Agent | IPs: 192.168.56.1 und 192.168.0.231 |
| Wazuh OVA 4.14.5 | SIEM/XDR-Server | Dashboard, Manager, Indexer |
| Kali Linux VM | Angriffssimulation | Erzeugt fehlgeschlagene SMB-Logins |
| Shuffle SOAR | Automatisierung | Lokal per Docker, Weboberflaeche auf Port 3001 |
| VirtualBox | Virtualisierung | Netzwerkbruecke und Host-only Adapter |

## 3. Wazuh OVA in VirtualBox bereitstellen

Die Wazuh-Umgebung wurde als OVA in Oracle VirtualBox betrieben. Fuer das Labor wurden zwei Netzwerkadapter genutzt:

1. **Netzwerkbruecke**: Zugriff auf das Wazuh Dashboard aus dem normalen Netzwerk.
2. **Host-only Adapter**: Kommunikation zwischen Wazuh-VM und Windows-Host im VirtualBox-Netz.

Nach dem Start der Wazuh-VM wurden die IP-Adressen im Terminal geprueft:

```bash
hostname -I
ip a
ip route
```

Im Projekt wurden diese Adressen verwendet:

```text
Wazuh Dashboard / normales Netzwerk: 192.168.0.214
Wazuh Host-only Netzwerk:          192.168.56.102
Windows Host-only Adresse:         192.168.56.1
Windows WLAN-Adresse:              192.168.0.231
```

## 4. Windows Wazuh-Agent konfigurieren

Der Windows-Agent zeigte zuerst auf eine alte Manager-IP. In der Datei `ossec.conf` war eine nicht mehr erreichbare Adresse eingetragen. Diese wurde auf die aktuelle Wazuh-Manager-IP angepasst.

Datei auf Windows oeffnen:

```powershell
notepad "C:\Program Files (x86)\ossec-agent\ossec.conf"
```

Manager-Adresse kontrollieren:

```powershell
Select-String -Path "C:\Program Files (x86)\ossec-agent\ossec.conf" -Pattern "<address>"
```

Wazuh-Agent-Dienst neu starten:

```powershell
Restart-Service WazuhSvc
Get-Service WazuhSvc
```

Agent-Verbindung auf der Wazuh-VM pruefen:

```bash
sudo /var/ossec/bin/agent_control -l
```

Erwartetes Ergebnis:

```text
ID: 001, Name: Obito-Win11, IP: any, Active
```

Damit war bestaetigt, dass der Windows-Agent aktiv mit dem Wazuh-Manager verbunden war.

## 5. Shuffle SOAR lokal starten

Shuffle wurde lokal auf dem Windows-Host mit Docker betrieben. Wenn Shuffle nicht erreichbar war, musste Docker Desktop gestartet und der Compose-Stack im Shuffle-Verzeichnis hochgefahren werden.

```powershell
docker compose up -d
docker ps
```

Shuffle war lokal ueber Port 3001 erreichbar:

```text
http://127.0.0.1:3001
```

## 6. Portweiterleitung fuer Wazuh -> Shuffle

Die Wazuh-VM konnte den lokalen Shuffle-Port `127.0.0.1:3001` des Windows-Hosts nicht direkt erreichen. Deshalb wurde eine Windows-Portproxy-Regel eingerichtet.

```powershell
netsh interface portproxy add v4tov4 listenaddress=192.168.56.1 listenport=3002 connectaddress=127.0.0.1 connectport=3001
netsh interface portproxy show all
```

Test von der Wazuh-VM:

```bash
curl --connect-timeout 5 -I http://192.168.56.1:3002
```

Dadurch konnte Wazuh Alerts an `192.168.56.1:3002` senden. Windows leitete diese Verbindung intern an Shuffle auf Port 3001 weiter.

## 7. Shuffle Workflow erstellen

In Shuffle wurde ein Workflow mit dem Namen `Wazuh Alert Test` erstellt.

Aufbau:

```text
Webhook Trigger -> Reaktionsschritt
```

Der Webhook empfaengt die Wazuh-Alerts. Der Reaktionsschritt gibt eine Analystenmeldung aus, zum Beispiel:

```text
SOAR-Massnahme ausgeloest: Logon Failure erkannt. Analyst soll Quelle pruefen und ggf. IP/Konto blockieren.
```

## 8. Wazuh Integration zu Shuffle eintragen

Auf der Wazuh-VM wurde in der Manager-Konfiguration `ossec.conf` ein Integrationsblock hinterlegt.

Bereinigtes Beispiel fuer GitHub:

```xml
<integration>
  <name>shuffle</name>
  <hook_url>http://192.168.56.1:3002/api/v1/hooks/WEBHOOK_ID</hook_url>
  <level>3</level>
  <alert_format>json</alert_format>
</integration>
```

Wazuh Manager danach neu starten:

```bash
sudo systemctl restart wazuh-manager.service
sudo systemctl status wazuh-manager.service --no-pager
```

## 9. Kali Linux Angriffssimulation

Auf Kali Linux wurde ein kontrollierter SMB-Login-Fehler erzeugt. Dabei wurde ein absichtlich falscher Benutzer mit falschem Passwort verwendet.

```bash
for i in {1..10}; do
  smbclient -L //192.168.56.1/ -U fakeuser%WrongPassword
  sleep 1
done
```

Erwartete Kali-Ausgabe:

```text
NT_STATUS_LOGON_FAILURE
```

## 10. Erkennung in Wazuh

Im Wazuh Dashboard wurde unter **Threat Hunting** nach den Login-Fehlern gesucht. Erwarteter Alert:

```text
Logon Failure - Unknown user or bad password
```

Der erkannte Alert wurde anschliessend an Shuffle weitergeleitet.

## 11. Ergebnis

Die komplette Kette wurde im Labor nachgewiesen:

```text
Kali smbclient Angriffssimulation
-> Windows Security Event
-> Wazuh Agent uebertraegt Event
-> Wazuh Manager erzeugt Alert
-> Wazuh sendet JSON an Shuffle Webhook
-> Shuffle startet Workflow Run
-> SOAR-Reaktionsmeldung wird erzeugt
```

## 12. Wichtiger Hinweis

Die Simulation ist nur fuer eigene, isolierte Laborumgebungen gedacht. Die Befehle duerfen nicht gegen fremde Systeme oder produktive Netzwerke ohne ausdrueckliche Freigabe verwendet werden.
