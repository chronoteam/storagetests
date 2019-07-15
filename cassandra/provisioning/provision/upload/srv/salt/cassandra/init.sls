cassandra|repo:
  pkgrepo.managed:
    - humanname: Cassandra Debian Repository
    - name: deb http://www.apache.org/dist/cassandra/debian 39x main
    - key_url: https://www.apache.org/dist/cassandra/KEYS
    - file: /etc/apt/sources.list.d/cassandra.list

cassandra|package:
  pkg.installed:
    - name: cassandra
    - require:
      - pkgrepo: cassandra|repo

# create list with all seeds ips
{% set seedIps = [] -%}
{%- set seedIpAddresses = salt['mine.get']('cassandra-seed_*', 'network.ipaddrs').items() %}
{% if seedIpAddresses|length %}
{% for hostname, ip in seedIpAddresses %}
{% do seedIps.append(ip[0]) -%}
{% endfor %}
{% endif %}

cassandra|config:
  file.managed:
    - name: /etc/cassandra/cassandra.yaml
    - source: salt://cassandra/files/cassandra.yaml
    - template: jinja
    - context:
      nodeIp: {{ salt['network.ipaddrs']()[0] }}
      seedIp: {{ seedIps | join(", ") }}

cassandra|service-stop:
  service.dead:
    - name: cassandra
    - sig: cassandra
    - require:
      - pkg: cassandra|package
      - file: /etc/cassandra/cassandra.yaml


cassandra|service:
  cmd.run:
    - name: rm -rf /var/lib/cassandra/data/system/*
    - runas: root
  service.running:
    - name: cassandra
    - enable: True
    {% if grains['id'].startswith('cassandra-node') %}
    - check_cmd:
      - "nc -z {{ seedIps[0] }} 9042; do sleep 1; done"
    {% endif %}
    - require:
      - service: cassandra|service-stop

cassandra|provision-schema-file:
  file.managed:
    - name: /srv/salt/cassandra/files/cassandra-schema.cql
    - source: salt://cassandra/files/cassandra-schema.cql
    - makedirs: True
