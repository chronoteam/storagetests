prometheus|remove-targets:
  file.absent:
    - name: /root/prometheus-targets

# grab all network interfaces and create config files for each machine
{%- set ips= salt['mine.get']('*', 'network.ipaddrs').items() %}
{% if ips|length %}
{%- for name, ip in ips %}
prometheus|deploy-target-{{ name }}:
  file.managed:
    - name: /root/prometheus-targets/{{ name }}.json
    - source: salt://prometheus/target.json
    - makedirs: True
    - template: jinja
    - context:
      ipAddress: {{ ip[0] }}
      hostname: {{ name }}
{% endfor %}
{% endif %}

prometheus|extract:
  archive.extracted:
    - name: /root
    - source: https://github.com/prometheus/prometheus/releases/download/v2.5.0/prometheus-2.5.0.linux-amd64.tar.gz
    - skip_verify: True

prometheus|deploy-config:
  file.managed:
    - name: /root/prometheus-2.5.0.linux-amd64/prometheus.yml
    - source: salt://prometheus/prometheus.yml

prometheus|systemd-unit:
  file.managed:
    - name: /etc/systemd/system/prometheus.service
    - source: salt://prometheus/files/prometheus.service
  module.wait:
    - name: service.systemctl_reload
    - onchanges:
      - file: prometheus|systemd-unit
    - require:
      - prometheus|extract

prometheus|running:
  service.running:
    - name: prometheus
    - enable: True
    - watch:
      - module: prometheus|systemd-unit
