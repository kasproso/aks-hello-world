FROM mcr.microsoft.com/windows/servercore:ltsc2019

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Add-WindowsFeature Web-Server; `Invoke-WebRequest -UseBasicParsing -Uri https://dotnetbinaries.blob.core.windows.net/servicemonitor/2.0.1.6/ServiceMonitor.exe -OutFile C:\ServiceMonitor.exe;

WORKDIR /inetpub/wwwroot
COPY ./bin/Release/PublishOutput/HelloWorld.exe .
COPY ./web.config .
EXPOSE 80

ENTRYPOINT ["C:\\ServiceMonitor.exe", "w3svc"]
