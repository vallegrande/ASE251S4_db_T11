FROM mcr.microsoft.com/mssql-tools:latest

WORKDIR /lab

COPY . /lab/

RUN chmod +x /lab/run.sh

ENTRYPOINT ["/bin/bash", "/lab/run.sh"]

CMD ["init"]