FROM ubuntu:22.04

RUN apt-get -y update && apt-get -y install curl zsh sudo git
RUN useradd -ms /bin/bash testuser
RUN echo "testuser  ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER testuser
WORKDIR /home/testuser
RUN mkdir -p /home/testuser/.dotfiles


CMD /bin/bash
