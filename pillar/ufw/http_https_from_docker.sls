{% from "ufw/vars.jinja" import vars with context %}
ufw:
  allow:
    http_https_from_docker:
      proto: tcp
      from:
        own_docker: 172.16.0.0/12
      to_port: 80,443