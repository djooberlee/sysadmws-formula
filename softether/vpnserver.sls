{% if (pillar['softether'] is defined) and (pillar['softether'] is not none) %}
  {%- if (pillar['softether']['install'] is defined) and (pillar['softether']['install'] is not none) and (pillar['softether']['install']) %}
    # Set some vars
    {%- set softether_version = pillar['softether']['version'] %}
    # This var is collected on jinja compilation, not sls execution
    {%- set softether_installed_version = salt['cmd.shell']("[ -d /opt/softether/git ] && git -C /opt/softether/git rev-parse --verify HEAD || echo ''") %}
    # If installed version differs from pillar or softether_force_install set - install softether
    {%- if (softether_version != softether_installed_version) or (pillar['softether_force_install'] is defined and pillar['softether_force_install'] is not none and pillar['softether_force_install']) %}
softether_depencies_installed:
  pkg.installed:
    - pkgs:
      {%- if grains['os'] in ['Ubuntu', 'Debian'] %}
      - git
      - build-essential
      - libreadline-dev
      - libncurses5-dev
      - libssl-dev
      - checkinstall
      - ca-certificates
      - zlib1g-dev
      {%- elif grains['os'] in ['CentOS', 'RedHat'] %}
      - gcc
      - openssl-devel
      - make
      - ncurses-devel
      - readline-devel
      - zlib-devel
      {%- endif %}

softether_repo:
  git.latest:
    - name: https://github.com/SoftEtherVPN/SoftEtherVPN_Stable.git
    - rev: {{ softether_version }}
    - target: /opt/softether/git
    - force_reset: True
    - force_clone: True

softether_vpnserver_stop:
  service.dead:
    - name: softether-vpnserver

softether_make_clean:
  cmd.run:
    - cwd: /opt/softether/git
    - name: 'make clean || /bin/true'

softether_configure:
  cmd.run:
    - cwd: /opt/softether/git
    - name: './configure'

softether_makefile_fixes_1:
  file.replace:
    - name: /opt/softether/git/Makefile
    - pattern: '^INSTALL_VPNSERVER_DIR=.*$'
    - repl: 'INSTALL_VPNSERVER_DIR=/opt/softether/vpnserver/'

softether_makefile_fixes_2:
  file.replace:
    - name: /opt/softether/git/Makefile
    - pattern: '^INSTALL_VPNBRIDGE_DIR=.*$'
    - repl: 'INSTALL_VPNBRIDGE_DIR=/opt/softether/vpnbridge/'

softether_makefile_fixes_3:
  file.replace:
    - name: /opt/softether/git/Makefile
    - pattern: '^INSTALL_VPNCLIENT_DIR=.*$'
    - repl: 'INSTALL_VPNCLIENT_DIR=/opt/softether/vpnclient/'

softether_makefile_fixes_4:
  file.replace:
    - name: /opt/softether/git/Makefile
    - pattern: '^INSTALL_VPNCMD_DIR=.*$'
    - repl: 'INSTALL_VPNCMD_DIR=/opt/softether/vpncmd/'

softether_make:
  cmd.run:
    - cwd: /opt/softether/git
    - name: 'make'

softether_checkinstall:
  cmd.run:
    - cwd: /opt/softether/git
    - name: 'checkinstall --install=yes -y --pkgname=softether --nodoc'

      {%- if (pillar['softether']['vpnserver'] is defined) and (pillar['softether']['vpnserver'] is not none) %}
        {%- if (pillar['softether']['vpnserver']['enabled'] is defined) and (pillar['softether']['vpnserver']['enabled'] is not none) and (pillar['softether']['vpnserver']['enabled']) %}
          {%- if grains['init'] == 'systemd' %}
softether_vpnserver_start_script_file:
  file.managed:
    - name: '/etc/systemd/system/softether-vpnserver.service'
    - source: '/opt/softether/git/systemd/softether-vpnserver.service'
    - mode: 0644
    - onchanges:
      - cmd: softether_checkinstall

softether_vpnserver_start_script_file_fixes_1:
  file.replace:
    - name: '/etc/systemd/system/softether-vpnserver.service'
    - pattern: '^ConditionPathExists=.*$'
    - repl: 'ConditionPathExists=!/opt/softether/vpnserver/do_not_run'
    - onchanges:
      - file: softether_vpnserver_start_script_file

softether_vpnserver_start_script_file_fixes_2:
  file.replace:
    - name: '/etc/systemd/system/softether-vpnserver.service'
    - pattern: '^EnvironmentFile=.*$'
    - repl: 'EnvironmentFile=-/opt/softether/vpnserver'
    - onchanges:
      - file: softether_vpnserver_start_script_file

softether_vpnserver_start_script_file_fixes_3:
  file.replace:
    - name: '/etc/systemd/system/softether-vpnserver.service'
    - pattern: '^ExecStart=.*$'
    - repl: 'ExecStart=/opt/softether/vpnserver/vpnserver start'
    - onchanges:
      - file: softether_vpnserver_start_script_file

softether_vpnserver_start_script_file_fixes_4:
  file.replace:
    - name: '/etc/systemd/system/softether-vpnserver.service'
    - pattern: '^ExecStop=.*$'
    - repl: 'ExecStop=/opt/softether/vpnserver/vpnserver stop'
    - onchanges:
      - file: softether_vpnserver_start_script_file

softether_vpnserver_start_script_file_fixes_5:
  file.replace:
    - name: '/etc/systemd/system/softether-vpnserver.service'
    - pattern: '^ReadWriteDirectories=.*$'
    - repl: 'ReadWriteDirectories=-/opt/softether/vpnserver'
    - onchanges:
      - file: softether_vpnserver_start_script_file

softether_vpnserver_systemd_reload:
  cmd.run:
    - name: 'systemctl daemon-reload'

softether_vpnserver__start:
  service.running:
    - name: softether-vpnserver
    - enable: True

          {%- elif grains['os'] in ['CentOS', 'RedHat'] and grains['osmajorrelease']|int == 6 %}
softether_vpnserver_start_script_file:
  file.managed:
    - name: '/etc/init.d/softether-vpnserver'
    - source: '/opt/softether/git/centos/SOURCES/init.d/vpnserver '
    - mode: 0755

          {%- elif grains['init'] in ['upstart','sysvinit'] %}
softether_vpnserver_start_script_file:
  file.managed:
    - name: '/etc/init.d/softether-vpnserver'
    - source: '/opt/softether/git/debian/softether-vpnserver.init'
    - mode: 0755

          {%- endif %}
        {%- endif %}
      {%- endif %}
    {%- endif %}
  {%- endif %}
{% endif %}
