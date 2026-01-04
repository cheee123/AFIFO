# Asynchronous FIFO
An asynchronous FIFO implementation using Gray code for clock domain crossing (CDC).

Test coverage:

- Basic Write/Read - Verifies simple data transfer through the FIFO

- Fill FIFO - Tests the full flag by filling to capacity

- Empty FIFO - Tests the empty flag by reading all data

- Simultaneous Read/Write - Tests concurrent operations from different clock domains