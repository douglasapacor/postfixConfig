FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  systemd \
  openssh-server \
  sudo \
  curl \
  nano \
  net-tools \
  nginx \
  php-fpm \
  php8.1-mbstring \
  php8.1-pdo \
  php8.1-mysql \
  php8.1-imap \
  certbot \
  && apt-get clean

  RUN mkdir -p /var/run/sshd \
  && chmod 0755 /var/run/sshd \
  && echo 'root:123' | chpasswd \
  && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
  && sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

EXPOSE 22 80

RUN systemctl enable ssh

CMD ["/lib/systemd/systemd"]