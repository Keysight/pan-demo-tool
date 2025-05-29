FROM docker-local-isg.artifactory.it.keysight.com/tiger/pan-demo-tool:local
COPY . .
RUN chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]
