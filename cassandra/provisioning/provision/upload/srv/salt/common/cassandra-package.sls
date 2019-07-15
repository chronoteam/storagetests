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
