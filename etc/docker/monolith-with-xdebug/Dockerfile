FROM magento2-monolith:dev

RUN sed -i "s|;zend_extension=xdebug.so|zend_extension=xdebug.so|g" /usr/local/etc/php/conf.d/zz-xdebug-settings.ini
RUN sed -i "s|listen = 0.0.0.0:9001|listen = 0.0.0.0:9002|g" /usr/local/etc/php-fpm.conf

RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:123123q' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
CMD ["sh", "-c", "/usr/sbin/sshd -D && php-fpm -R"]
