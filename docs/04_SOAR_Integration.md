# 04 - SOAR Integration mit Shuffle

## Ziel

Wazuh soll Alerts automatisch an Shuffle SOAR senden. Shuffle soll den Eingang verarbeiten und eine kontrollierte Reaktionsmeldung erzeugen.

## Workflow-Aufbau

Der Workflow besteht aus zwei Schritten:

```text
Webhook Trigger -> Reaktionsschritt
```

Der Webhook empfaengt den Wazuh-Alert. Der Reaktionsschritt formuliert eine Analystenmeldung.

## Wazuh-Konfiguration

Die Integration wird in der Wazuh-Manager-Konfiguration `ossec.conf` hinterlegt. Fuer GitHub wurde die Hook-URL bereinigt:

```xml
<integration>
  <name>shuffle</name>
  <hook_url>http://192.168.56.1:3002/api/v1/hooks/WEBHOOK_ID</hook_url>
  <level>3</level>
  <alert_format>json</alert_format>
</integration>
```

## Neustart

```bash
sudo systemctl restart wazuh-manager.service
sudo systemctl status wazuh-manager.service --no-pager
```

## Reaktionsmeldung

```text
SOAR-Massnahme ausgeloest: Logon Failure erkannt. Analyst soll Quelle pruefen und ggf. IP/Konto blockieren.
```

## Warum keine automatische Sperre?

Eine automatische Blockierung kann in produktiven Netzen legitime Benutzer aussperren, wenn ein Fehlalarm entsteht. Fuer ein erstes SIEM-SOAR-Lab ist eine Analystenmeldung daher fachlich sinnvoller. Eine echte Sperre sollte erst mit klaren Bedingungen, Freigabeprozess, Logging und Rollback eingesetzt werden.
