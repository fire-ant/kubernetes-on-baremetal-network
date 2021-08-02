FROM debian:buster-slim

RUN apt update && apt install inotify-tools -y && apt clean

COPY sources.list /etc/apt/sources.list
COPY trusted.gpg /etc/apt/trusted.gpg

RUN apt update && apt install -y openssh-server \
    python3-apt ifupdown2 python-apt iputils-ping tcpdump traceroute bridge-utils iptables


COPY file-watcher /
ENTRYPOINT ["/file-watcher"]