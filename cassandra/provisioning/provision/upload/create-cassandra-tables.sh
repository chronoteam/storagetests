#!/usr/bin/env bash

sudo salt cassandra-seed_0 cmd.run 'cqlsh -f /srv/salt/cassandra/files/cassandra-schema.cql'