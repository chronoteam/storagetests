CREATE KEYSPACE IF NOT EXISTS cronostrr
WITH REPLICATION = {
'class' : 'SimpleStrategy',
'replication_factor' : 2
};

use cronostrr;

CREATE TABLE IF NOT EXISTS customers (
id UUID PRIMARY KEY,
name text,
email text,
country text,
company text,
position text
);