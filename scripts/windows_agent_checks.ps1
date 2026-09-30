# Windows Agent and Shuffle connectivity checks

Write-Host "== Network =="
ipconfig

Write-Host "== Wazuh service =="
Get-Service WazuhSvc

Write-Host "== Wazuh manager address in agent config =="
Select-String -Path "C:\Program Files (x86)\ossec-agent\ossec.conf" -Pattern "<address>"

Write-Host "== Portproxy rules =="
netsh interface portproxy show all

Write-Host "== Docker containers =="
docker ps
