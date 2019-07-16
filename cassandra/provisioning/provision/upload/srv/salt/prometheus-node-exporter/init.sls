extract-prometheus-node-exporter:
  archive.extracted:
    - name: /root
    - source: https://github.com/prometheus/node_exporter/releases/download/v0.17.0-rc.0/node_exporter-0.17.0-rc.0.linux-amd64.tar.gz
    - skip_verify: True

node-exporter-systemd-unit:
  file.managed:
    - name: /etc/systemd/system/node-exporter.service
    - source: salt://prometheus-node-exporter/files/node-exporter.service
  module.wait:
    - name: service.systemctl_reload
    - onchanges:
      - file: node-exporter-systemd-unit
    - require:
      - extract-prometheus-node-exporter

node-exporter-running:
  service.running:
    - name: node-exporter
    - enable: True
    - watch:
      - module: node-exporter-systemd-unit