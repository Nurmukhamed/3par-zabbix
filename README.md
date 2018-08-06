# 3par-zabbix
Simple script to discovery 3par disk arrays

* Create ssh account on 3par disk array
* connect to 3par, run "showinventory", save output to file "inventory.txt"
* run perl 3par/inventory.pl <inventory.txt > inventory.json
* add zabbix-agent conf, reload zabbix-agent
* check new items at zabbix server

