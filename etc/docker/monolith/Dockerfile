FROM paliarush123/minikube-php-fpm:latest

RUN   sed -i "s|listen = 0.0.0.0:9000|listen = 0.0.0.0:9001|g" /usr/local/etc/php-fpm.conf

# RUN apt-get update && apt-get install -y nfs-common && rm -rf /var/lib/apt/lists/*
