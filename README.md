# Cronalytics.io bash script.
A bash script that will run  an arbitrary command and send details to the https://cronalytics.io API.


# Usage
```cronalytics.io <public hash> <bash command to run>```

You can add the above script in front of any entry in your crontab and the details will be reported to cronalytics.io

1. goto https://dashboard.cronalytics.io/setup (or https://cronalytics.io and follow the links)
1. enter your cron details
1. edit your crontab ```crontab -e```
1. after the cron expression (eg: * * * * *) and before your script enter the location of the script
1. save the crontab


eg:
```*/2 * * * * ~/bin/cronalytics.sh cf401e2b2d0addc08293d9694b8cc3f50a831837 echo "doing work"```