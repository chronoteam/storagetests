package main

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"sync"

	faker2 "github.com/bgadrian/fastfaker/faker"
)
import "github.com/gocql/gocql"

type TimelineMessage struct {
	ID              string
	Timestamp       int64
	BodyID          string
	ProducerGroupID string
	LockConsumerID  string
	Size            int
	Version         int
}

func main() {
	cassHost := os.Getenv("CASSANDRA_HOST")
	cassKeyspace := os.Getenv("CASSANDRA_KEYSPACE")
	cassTable := os.Getenv("CASSANDRA_TABLE")
	toInsert, _ := strconv.Atoi(os.Getenv("TIMELINE_COUNT"))
	workers, _ := strconv.Atoi(os.Getenv("WORKERS_COUNT"))

	cluster := gocql.NewCluster(cassHost)
	cluster.Keyspace = cassKeyspace
	cluster.Consistency = gocql.Quorum

	wg := sync.WaitGroup{}
	wg.Add(workers)

	for w := 0; w < workers; w++ {
		go func() {
			session, _ := cluster.CreateSession()
			defer session.Close()
			faker := faker2.NewFastFaker()
			m := TimelineMessage{}

			docsCount := toInsert / workers
			for i := 0; i < docsCount; i++ {
				m.ID = faker.UUID()
				m.Version = faker.Intn(256)
				m.Size = int(faker.Int16())
				m.LockConsumerID = faker.BeerStyle()
				m.ProducerGroupID = "consum" + strconv.Itoa(faker.Intn(25))
				m.BodyID = faker.UUID()

				// insert a tweet
				insertStatement := `INSERT INTO ? (id, timestamp, bodyID, producerGroupID, lockConsumerID, size, version) VALUES (?, ?, ?,?,?,?,?)`
				if err := session.Query(insertStatement,
					cassTable,
					m.ID, m.Timestamp, m.BodyID, m.ProducerGroupID,
					m.LockConsumerID, m.Size, m.Version).
					Exec(); err != nil {
					log.Printf("closing worker with error=%s\n", err)
					return
				}
			}
			fmt.Printf("inserted %d documents in %s\n", docsCount, cassTable)
			wg.Done()
		}()
	}

	wg.Wait()
	fmt.Println("DONE")
}
