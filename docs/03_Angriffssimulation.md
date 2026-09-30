# 03 - Angriffssimulation

## Zweck

Die Simulation soll einen realistischen, aber kontrollierten Login-Fehler erzeugen. Dadurch kann Wazuh zeigen, ob Windows Security Events aufgenommen und als Alert dargestellt werden.

## Voraussetzung

- Test nur im eigenen Lab
- Windows-Zielsystem ist erreichbar
- Wazuh-Agent auf Windows ist aktiv
- Wazuh Dashboard zeigt den Agenten als verbunden an

## Testbefehl auf Kali Linux

```bash
for i in {1..10}; do
  smbclient -L //192.168.56.1/ -U fakeuser%WrongPassword
  sleep 1
done
```

## Erwartete Ausgabe auf Kali

```text
NT_STATUS_LOGON_FAILURE
```

## Erwartete Erkennung in Wazuh

Im Wazuh Dashboard unter **Threat Hunting** sollten Alerts mit folgender Beschreibung erscheinen:

```text
Logon Failure - Unknown user or bad password
```

## Beweissicherung

Fuer eine Projektdokumentation eignen sich folgende Screenshots:

1. Kali-Ausgabe mit `NT_STATUS_LOGON_FAILURE`
2. Wazuh Threat Hunting mit Login-Fehler-Alerts
3. Detailansicht des Wazuh Alerts
4. Shuffle Workflow Run nach Eingang des Alerts
