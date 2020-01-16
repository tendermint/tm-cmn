GOTOOLS = github.com/golangci/golangci-lint/cmd/golangci-lint
PACKAGES=$(shell go list ./...)
INCLUDE = -I=${GOPATH}/src/github.com/tendermint/tm-db -I=${GOPATH}/src -I=${GOPATH}/src/github.com/gogo/protobuf/protobuf

export GO111MODULE = on

all: lint test

### go tests
## By default this will only test memdb & goleveldb
test:
	@echo "--> Running go test"
	@go test -p 1 $(PACKAGES)

test-cleveldb:
	@echo "--> Running go test"
	@go test -p 1 $(PACKAGES) -tags cleveldb

test-rocksdb:
	@echo "--> Running go test"
	@go test -p 1 $(PACKAGES) -tags rocksdb

test-boltdb:
	@echo "--> Running go test"
	@go test -p 1 $(PACKAGES) -tags boltdb

test-all:
	@echo "--> Running go test"
	@go test -p 1 $(PACKAGES) -tags cleveldb,rocksdb,boltdb

lint:
	@echo "--> Running linter"
	@golangci-lint run
	@go mod verify

# TODO: install dbs

tools:
	go get -v $(GOTOOLS)

# generates certificates for TLS testing in remotedb
gen_certs: clean_certs
	certstrap init --common-name "tendermint.com" --passphrase ""
	certstrap request-cert --common-name "remotedb" -ip "127.0.0.1" --passphrase ""
	certstrap sign "remotedb" --CA "tendermint.com" --passphrase ""
	mv out/remotedb.crt db/remotedb/test.crt
	mv out/remotedb.key db/remotedb/test.key
	rm -rf out

clean_certs:
	rm -f db/remotedb/test.crt
	rm -f db/remotedb/test.key

%.pb.go: %.proto
	## If you get the following error,
	## "error while loading shared libraries: libprotobuf.so.14: cannot open shared object file: No such file or directory"
	## See https://stackoverflow.com/a/25518702
	## Note the $< here is substituted for the %.proto
	## Note the $@ here is substituted for the %.pb.go
	protoc $(INCLUDE) $< --gogo_out=Mgoogle/protobuf/timestamp.proto=github.com/golang/protobuf/ptypes/timestamp,plugins=grpc:../../..

protoc_remotedb: remotedb/proto/defs.pb.go	
	