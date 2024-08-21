FROM ubuntu:latest
LABEL authors="ratul"

ENTRYPOINT ["top", "-b"]