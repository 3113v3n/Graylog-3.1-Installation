# Graylog Scripts
_This Repository contains scripts to help in **Automation** of graylog-3.1 installation


#### graylog_install.sh

This script aids in the installation of graylog 3.1 and graylog 3.3 on debian 9 and 10.
It also performs system clean up incase you need to uninstall graylog.
[`graylog_install.sh`](https://github.com/3113v3n/Graylog-3.1-Installation/blob/main/graylog_install.sh)

    USAGE:
      ./graylog_install.sh -i [Debian_Version]



#### graylog_nginx_install.sh
This script helps in Nginx and certificate installation for Graylog Server.
It requires you to be **root** so ensure to change to _ROOT USER_ before running scripts
> also remember to source the file to avoid errors

[`nginx_install.sh`](https://github.com/3113v3n/Graylog-3.1-Installation/blob/main/nginx_install.sh)

     USAGE:
       source graylog_nginx_install -d <domain_name> -e <email>
