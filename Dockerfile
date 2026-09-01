FROM ubuntu:26.04

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get -y update && apt-get -y install curl sudo git xz-utils locales locales-all zsh
RUN useradd -ms /bin/bash testuser
RUN echo "testuser  ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER testuser
WORKDIR /home/testuser
RUN mkdir -p /home/testuser/.dotfiles

CMD ["/bin/bash", "-l"]
