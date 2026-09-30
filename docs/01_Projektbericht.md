# 01 - Projektbericht: Wazuh SIEM und Shuffle SOAR

## 1. Einleitung

Ziel dieses Laborprojekts war es, einen einfachen Security-Vorfall technisch nachvollziehbar zu simulieren, zentral zu erkennen und an ein SOAR-System weiterzuleiten. Die Umgebung bestand aus Kali Linux als Test-Angreifer, Windows 11 als Zielsystem mit Wazuh-Agent, einer Wazuh OVA VM als SIEM/XDR-Plattform und Shuffle SOAR als Automatisierungsplattform.

Der Test wurde bewusst in einer kontrollierten Laborumgebung durchgefuehrt. Es wurden keine fremden Systeme angegriffen.

## 2. Zielsetzung

Die Leitfrage lautete:

> Wie kann ein simulierter Login-Fehler-Angriff in einer lokalen Laborumgebung von Wazuh erkannt und anschliessend automatisch an Shuffle SOAR weitergeleitet werden?

Erwartetes Ergebnis war eine nachvollziehbare Kette von der Angriffssimulation bis zur Reaktionsmeldung im SOAR-Workflow.

## 3. Eingesetzte Komponenten

| Komponente | Rolle | Relevante IP/Port-Angaben | Aufgabe |
|---|---|---|---|
| Kali Linux VM | Angreifer im Lab | Host-only-Netz | Erzeugt fehlgeschlagene SMB-Logins |
| Windows 11 Host | Zielsystem und Docker-Host | 192.168.56.1, 192.168.0.231 | Wazuh-Agent, Shuffle/Docker |
| Wazuh OVA VM | SIEM/XDR-Server | 192.168.0.214, 192.168.56.102 | Empfang, Analyse und Alerting |
| Shuffle SOAR | Automatisierung | 3001 lokal, 3002 als Portproxy | Webhook-Empfang und Workflow-Run |

## 4. Umsetzung

### 4.1 Wazuh-VM und Netzwerk

Die Wazuh-VM wurde in Oracle VirtualBox betrieben. Die Umgebung nutzte zwei Netzwerke: ein normales Netzwerk fuer den Zugriff auf das Dashboard und ein Host-only-Netz fuer die Kommunikation zwischen Wazuh-VM, Windows-Host und Shuffle-Portproxy.

Wichtige Pruefbefehle:

```bash
hostname -I
ip a
ip route
```

### 4.2 Windows-Agent

Ein zentrales Problem war, dass der Windows-Agent zunaechst noch auf eine alte Manager-Adresse zeigte. Die Adresse wurde in der Datei `C:\Program Files (x86)\ossec-agent\ossec.conf` angepasst. Danach wurde der Dienst `WazuhSvc` neu gestartet.

```powershell
notepad "C:\Program Files (x86)\ossec-agent\ossec.conf"
Restart-Service WazuhSvc
Get-Service WazuhSvc
```

Auf der Wazuh-VM wurde der Agent-Status geprueft:

```bash
sudo /var/ossec/bin/agent_control -l
```

Ergebnis: Der Agent `Obito-Win11` wurde als aktiv angezeigt.

## 5. Angriffssimulation

Die Simulation bestand aus wiederholten fehlgeschlagenen SMB-Anmeldeversuchen. Dazu wurde ein absichtlich falscher Benutzer mit falschem Passwort verwendet:

```bash
for i in {1..10}; do
  smbclient -L //192.168.56.1/ -U fakeuser%WrongPassword
  sleep 1
done
```

Auf Kali wurde die Meldung `NT_STATUS_LOGON_FAILURE` sichtbar. Auf Windows entstanden dadurch Security Events, die vom Wazuh-Agent an den Wazuh-Manager uebertragen wurden.

## 6. Erkennung in Wazuh

Im Wazuh Dashboard erschien der Vorfall im Bereich **Threat Hunting** als Alert:

```text
Logon Failure - Unknown user or bad password
```

Damit wurde nachgewiesen, dass der fehlgeschlagene Netzwerk-Login nicht nur lokal auf Kali sichtbar war, sondern zentral durch Wazuh erfasst und bewertet wurde.

## 7. Shuffle SOAR Integration

### 7.1 Webhook-Workflow

In Shuffle wurde ein Workflow mit dem Namen `Wazuh Alert Test` erstellt. Als Eingang diente ein Webhook-Trigger. Der Wazuh-Manager leitete Alerts im JSON-Format an diesen Webhook weiter.

Da Shuffle lokal in Docker auf Windows lief, wurde eine Portweiterleitung eingerichtet:

```powershell
netsh interface portproxy add v4tov4 listenaddress=192.168.56.1 listenport=3002 connectaddress=127.0.0.1 connectport=3001
```

Verbindungstest von der Wazuh-VM:

```bash
curl --connect-timeout 5 -I http://192.168.56.1:3002
```

### 7.2 Wazuh Integration

In der `ossec.conf` des Wazuh-Managers wurde ein Integrationsblock fuer Shuffle hinzugefuegt. Die oeffentliche Version im Repository ist bewusst bereinigt und enthaelt keinen echten Webhook-Identifier.

```xml
<integration>
  <name>shuffle</name>
  <hook_url>http://192.168.56.1:3002/api/v1/hooks/WEBHOOK_ID</hook_url>
  <level>3</level>
  <alert_format>json</alert_format>
</integration>
```

Danach wurde der Wazuh Manager neu gestartet:

```bash
sudo systemctl restart wazuh-manager.service
sudo systemctl status wazuh-manager.service --no-pager
```

## 8. SOAR-Reaktion

Als sichere erste Reaktion wurde keine echte IP-Sperre umgesetzt. Stattdessen erzeugte Shuffle eine kontrollierte Analystenmeldung:

```text
SOAR-Massnahme ausgeloest: Logon Failure erkannt. Analyst soll Quelle pruefen und ggf. IP/Konto blockieren.
```

Diese Vorgehensweise ist fuer ein Lab sinnvoll, weil automatische Sperren Fehlalarme verursachen koennen. In einer produktiven Umgebung waeren zusaetzliche Bedingungen, Freigaben, Logging und Rollback-Optionen notwendig.

## 9. Ergebnis

Das Projektziel wurde erreicht. Die Kette von Angriffssimulation, Erkennung, Alert-Weiterleitung und SOAR-Reaktion wurde praktisch nachgewiesen.

## 10. Erweiterungsmoeglichkeiten

Moegliche naechste Schritte:

- Ticket-Erstellung im SOAR-Workflow
- E-Mail-Benachrichtigung an Analysten
- Threat-Intelligence-Anreicherung der Quell-IP
- kontrollierte Firewall-Regel nach manueller Freigabe
- bessere Dashboards fuer Reporting und Metriken
- weitere Testfaelle wie File Integrity Monitoring oder SSH-Fehlversuche in Linux-Labs
