# PROJETO DE MENSSAGEIRO PRÓPRIO

## REQUISITOS DO PROJETO
---
        1. MÁQUINA UBUNTU
            1.1. MÁQUINA AWS ECS/LIGTHSAIL
            1.2. CONTAINER DOCKER
                1.2.1. CONSTRUÇÃO DO IMAGEM
                1.2.2. CONSTRUÇÃO DO CONTAINER APARTIR DA IMAGEM
                1.2.3. CONECTAR NO CONTAINER
                1.2.4. OBSERVAÇÕES REFERENTE AO SSH NO CONTAINER
        2. INSTALAÇÃO DE LOCALES E TZDATA        
        3. BANCO DE DADOS (MARIADB)
        4. POSTFIX
        5. DOVECOT
        6. POSTFIXADMIN
        7. NGINX
        8. CONFIGURAÇÃO INICIAL NO POSTFIXADMIN
            8.1 ACESSAR O POSTFIXADMIN
            8.2 CRIAR OS DOMÍNIOS
            8.3 CRIAR CONTAS DE E-MAIL
        9. CONFIGURAR DNS PARA OS DOMÍNIOS
        10. CONFIGURAR CERTIFICADOS SSL/TLS
        11. CONFIGURAR DKIM
        12. USAR O CERTIFICADO A1 PARA PUBLICACOESINR.COM.BR
        13. OBSERVAÇÕES FINAIS

### 1. MÁQUINA UBUNTU
---
O host do projeto será um sistema debian mais precisamente ubuntu 22.4

#### 1.1. Máquina aws ecs/ligthsail
---
Em uma máquina aws ecs/ligthsail podemos atualizar o sistema:
  ````bash
    $ apt-get update && apt-get upgrade
  ````
Após atualização Pode-se iniciar a instalação dos demais items (Item 2. INSTALAÇÃO DE LOCALES E TZDATA em diante)
 
#### 1.2. Container docker
---
No caso do Container podemos usar o seguinte Dockerfile:
````docker
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
  && apt-get clean

  RUN mkdir -p /var/run/sshd \
  && chmod 0755 /var/run/sshd \
  && echo 'root:123' | chpasswd \
  && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
  && sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

EXPOSE 22 80

RUN systemctl enable ssh

CMD ["/lib/systemd/systemd"]
````

##### 1.2.1. Construção do Imagem
---
````bash
    $ docker build -t my-ubuntu-image .
````

##### 1.2.2. Construção do container apartir da imagem
---
````bash
    $ docker run --privileged -d --name ubuntu -p 2222:22 -p 8080:80 my-ubuntu-image
````

##### 1.2.3. Conectar no container
---
````bash
    # docker exec -it ubuntu bash
````

##### 1.2.4. Observações referente ao ssh no container
---
Pode ser necessário verificação de configuração extra para habilitar conexão ssh.
    
> Caminho do arquivo de configuração do ssh "/etc/ssh/sshd_config"

Identifique as seguinte opções:

>  PermitRootLogin yes
>  UsePAM no

### 2. INSTALAÇÃO DE LOCALES E TZDATA
---
````bash
    $ apt update && apt install -y locales
    $ apt update && apt install -y tzdata
````
Após a instalação e confirmação do prompt rode os seguintes comandos:
````bash
    $ locale-gen pt_BR.UTF-8 && update-locale LANG=pt_BR.UTF-8 && \ echo "LANG=pt_BR.UTF-8"> /etc/default/locale

    $ ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && dpkg-reconfigure -f noninteractive tzdata
````

### 3. BANCO DE DADOS (MARIADB)
---
Instalação do banco de dados para uso do postfix e postfixAdmin.

````bash
    $ apt update && apt install -y mariadb-server mariadb-client
````
Após a finalização da instalação deve-se iniciar o banco de dados e então colocar na 
inicialização do sistema.

````bash
    $ systemctl start mariadb
    $ systemctl enable mariadb
    $ systemctl status mariadb
````
Após finalização do processo de instalação é necessário criar o banco e usuário que será usado pelo postfix e postfixAdmin.

````bash
    $ mysql
    $ CREATE DATABASE postfixadmin;
    $ GRANT ALL PRIVILEGES ON postfixadmin.* TO 'postfixadmin'@'localhost' IDENTIFIED BY 'postfixpassword';
    $ FLUSH PRIVILEGES;
    $ EXIT;
````

### 4. POSTFIX
---
````bash
    $ apt install -y postfix
````

Caso a instalação requisite o tipo de instalação selecione:

> Internet Site

Após a ocnclusão da instalação deve-se realizar a configuração atravez do arquivo:

````bash
    $ nano /etc/postfix/main.cf
````

Verificar as seguintes configurações no arquivo:

        myhostname = mail.epicquestti.com.br
        mydestination = $myhostname, localhost
        mynetworks = 127.0.0.0/8
        inet_interfaces = all
        inet_protocols = ipv4
        home_mailbox = Maildir/
        smtpd_banner = $myhostname ESMTP

Reinicie o postfix

````bash
    $ systemctl restart postfix
````

### 5. DOVECOT
---
````bash
    $ apt install -y dovecot-core dovecot-imapd
````

Após a instalação do dovecot deve se configurar atravez do arquivo:

````bash
    $ nano /etc/dovecot/dovecot.conf
````

````ini
    protocols = imap
    mail_location = maildir:~/Maildir
````

````bash
    $ systemctl enable dovecot
    $ systemctl start dovecot
````

### 6. POSTFIXADMIN
---
````bash
    $ apt install -y postfixadmin
````

Caso o arquivo não exista deve-se copiar:

````bash
    $ cp /usr/share/postfixadmin/config.inc.php /etc/postfixadmin/config.local.php
    $ nano /etc/postfixadmin/config.local.php
````

Configurações do arquivo config.local.php:

````php
        $CONF['configured'] = true;
        $CONF['database_type'] = 'mysqli';
        $CONF['database_host'] = 'localhost';
        $CONF['database_user'] = 'postfixadmin';
        $CONF['database_password'] = 'postfixpassword';
        $CONF['database_name'] = 'postfixadmin';
        $CONF['default_domain'] = 'epicquestti.com.br';
        $CONF['admin_email'] = 'admin@epicquestti.com.br';
````

### 7. NGINX
---
````bash
    $ apt-get update && apt-get install -y nginx php-fpm
````

Após a instalação configuramos atravez do arquivo:

````bash
    $ /etc/nginx/sites-available/postfixadmin
````

Verificamos a localização dos arquivos do postfixAdmin para a configuração correta:

````php
    root /var/www/html/postfixadmin/public;
    root /usr/share/postfixadmin/public;
````

````php
server {
    listen 80;
    server_name postfixadmin.local;

    root /usr/share/postfixadmin/public;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    error_log /var/log/nginx/postfixadmin_error.log;
    access_log /var/log/nginx/postfixadmin_access.log;
}
````

Após p arquivo configurado criamos o link simbólico

````bash
    $ ln -s /etc/nginx/sites-available/postfixadmin /etc/nginx/sites-enabled/
````

Após a configuração do arquivo reiniciamos o nginx

````bash
    $ systemctl restart nginx
````

### 8. CONFIGURAÇÃO INICIAL NO POSTFIXADMIN
---
#### 8.1 ACESSAR O POSTFIXADMIN

Faça login na interface web do PostfixAdmin.

#### 8.2 CRIAR OS DOMÍNIOS

Clique em "Create Domain".
Preencha:
Domain: Insira epicquestti.com.br e configure as opções, como limite de caixas postais e cotas. Salve.
Repita o mesmo para publicacoesinr.com.br.
Certifique-se de que ambos os domínios aparecem na lista de domínios após a criação.

#### 8.3 CRIAR CONTAS DE E-MAIL

Para cada domínio, adicione as contas de e-mail necessárias:
Clique em "Add Mailbox".
Escolha o domínio, insira o nome da conta (exemplo: admin@epicquestti.com.br) e configure a senha.
Salve e repita para os usuários necessários nos dois domínios.

### 9. CONFIGURAR DNS PARA OS DOMÍNIOS
---
No provedor de DNS configure as seguintes entradas para ambos os domínios:
Entrada MX (Servidor de e-mails):

    Nome: @ (ou deixe vazio, dependendo do provedor)
    Tipo: MX
    Valor: mail.seudominio.com.br (o nome do servidor que está configurando)
    Prioridade: 10
        
Entrada A (IP do servidor de e-mail):

    Nome: mail
    Tipo: A
    Valor: o IP público do servidor
    
Registro SPF:

        Nome: @
        Tipo: TXT
        Valor: v=spf1 mx -all
        
Registros DKIM:

        Gere a chave pública e privada para DKIM (explicado na próxima etapa).
        Adicione um registro TXT para cada domínio com o nome e valor correspondentes.
        
Registro DMARC:

    Nome: _dmarc
    Tipo: TXT
    Valor: v=DMARC1; p=quarantine; rua=mailto:postmaster@seudominio.com.br; ruf=mailto:postmaster@seudominio.com.br; sp=none; aspf=r;
    
### 10. CONFIGURAR CERTIFICADOS SSL/TLS
---
Os certificados SSL/TLS são necessários para criptografar conexões de e-mail. Configure cada domínio.
Certificados SSL/TLS com Let's Encrypt (Certbot):
Instale o Certbot: No servidor, instale o Certbot:

````bash
    $ sudo apt update
    $ sudo apt install certbot
````

Obtenha os certificados para cada domínio:
Execute o comando abaixo para cada domínio:

````bash
    $ sudo certbot certonly --standalone -d mail.epicquestti.com.br -d mail.publicacoesinr.com.br
````

Os certificados serão salvos em:

````bash
    $ /etc/letsencrypt/live/mail.epicquestti.com.br/
    $ /etc/letsencrypt/live/mail.publicacoesinr.com.br/
````

Configurar o Postfix para usar os certificados no arquivo "/etc/postfix/main.cf" adicione:

````ini
    smtpd_tls_cert_file = /etc/letsencrypt/live/mail.epicquestti.com.br/fullchain.pem
    smtpd_tls_key_file = /etc/letsencrypt/live/mail.epicquestti.com.br/privkey.pem
    smtpd_tls_CAfile = /etc/letsencrypt/live/mail.epicquestti.com.br/chain.pem
    smtpd_use_tls = yes
    smtpd_tls_security_level = may

    smtp_tls_cert_file = /etc/letsencrypt/live/mail.publicacoesinr.com.br/fullchain.pem
    smtp_tls_key_file = /etc/letsencrypt/live/mail.publicacoesinr.com.br/privkey.pem
    smtp_tls_CAfile = /etc/letsencrypt/live/mail.publicacoesinr.com.br/chain.pem
    smtp_tls_security_level = may
````

Configurar o Dovecot para usar os certificados no arquivo "/etc/dovecot/conf.d/10-ssl.conf", adicione:

````ini
    ssl_cert = </etc/letsencrypt/live/mail.epicquestti.com.br/fullchain.pem
    ssl_key = </etc/letsencrypt/live/mail.epicquestti.com.br/privkey.pem
````

### 11. Configurar DKIM
---
#### Gerar as chaves DKIM:

Gere as chaves para cada domínio:

````bash
    $ opendkim-genkey -t -s default -d epicquestti.com.br
    $ opendkim-genkey -t -s default -d publicacoesinr.com.br
````

Os arquivos gerados serão:
default.private: A chave privada.
default.txt: A chave pública para adicionar ao DNS.

Configure o OpenDKIM edite o arquivo /etc/opendkim/KeyTable

````ini
    default._domainkey.epicquestti.com.br epicquestti.com.br:default:/etc/opendkim/keys/epicquestti.com.br/default.private
    default._domainkey.publicacoesinr.com.br publicacoesinr.com.br:default:/etc/opendkim/keys/publicacoesinr.com.br/default.private
````

Adicione os registros DKIM no DNS.

### 12. USAR O CERTIFICADO A1 PARA PUBLICACOESINR.COM.BR
---
Se você está usando um certificado A1, não precisa do Certbot para este domínio. Use os arquivos do certificado A1 diretamente.
Converta o arquivo PFX para PEM:

````bash
    $ openssl pkcs12 -in certificado-a1.pfx -out fullchain.pem -nodes -clcerts
    $ openssl pkcs12 -in certificado-a1.pfx -out privkey.pem -nocerts -nodes
````

Configure o Postfix para usar o certificado A1 no /etc/postfix/main.cf:

````ini
    smtpd_tls_cert_file = /caminho/para/fullchain.pem
    smtpd_tls_key_file = /caminho/para/privkey.pem
````

Configure o Dovecot para usar o certificado A1 no /etc/dovecot/conf.d/10-ssl.conf:

````ini
    ssl_cert = </caminho/para/fullchain.pem
    ssl_key = </caminho/para/privkey.pem
````
   
 Reinicie os serviços:
 
````bash
    $ sudo systemctl restart postfix dovecot
````

### 13. OBSERVAÇÕES FINAIS
---
- Excluímos o arquivo default que é gerado durante a instalação do Nginx (em /etc/nginx/sites-available e /etc/nginx/sites-enabled).
- Verificamos a versão do php no arquivo "etc/postfixadmin/config.local.php".
- verificamos a configuração ssh para viabilizar a conexão.
- Ao inserir variaveis no arquivo "etc/postfixadmin/config.local.php" verificar sintaxe ";".
- Devemos dar permissão para o nginx acessar os arquivo do postfixadmin:

````bash
    $ chown -R www-data:www-data /usr/share/postfixadmin
    $ chmod -R 755 /usr/share/postfixadmin
````

Lembrando que podemos ter esse arquivos em locais diferente:

> /var/www/html/postfixadmin/public;

Sendo assim as permissões do Nginx deve ser configurada nesse diretório.