base:
  '*':
    - prometheus-node-exporter
  'provision':
    - common.ubuntu-swap
    - prometheus
  'cassandra-*':
    - common.ubuntu-swap
    - common.java8
   # - cassandra
