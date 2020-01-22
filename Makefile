export CGO_ENABLED=0
export GO111MODULE=on

.PHONY: build

ATOMIX_CONSUL_RAFT_NODE_VERSION := latest

all: build

build: # @HELP build the source code
build:
	GOOS=linux GOARCH=amd64 go build -o build/_output/atomix-consul-raft-node ./cmd/atomix-consul-raft-node

test: # @HELP run the unit tests and source code validation
test: build license_check linters
	go test github.com/atomix/atomix-consul-raft-node/...

coverage: # @HELP generate unit test coverage data
coverage: build linters license_check
	go test github.com/atomix/atomix-consul-raft-node/pkg/... -coverprofile=coverage.out.tmp -covermode=count
	@cat coverage.out.tmp | grep -v ".pb.go" > coverage.out

linters: # @HELP examines Go source code and reports coding problems
	golangci-lint run

license_check: # @HELP examine and ensure license headers exist
	./build/licensing/boilerplate.py -v

proto: # @HELP build Protobuf/gRPC generated types
proto:
	docker run -it -v `pwd`:/go/src/github.com/atomix/atomix-consul-raft-node \
		-w /go/src/github.com/atomix/atomix-consul-raft-node \
		--entrypoint build/bin/compile_protos.sh \
		onosproject/protoc-go:stable

image: # @HELP build atomix-consul-raft-node Docker image
image: build
	docker build . -f build/docker/Dockerfile -t atomix/atomix-consul-raft-node:${ATOMIX_CONSUL_RAFT_NODE_VERSION}

benchmarks: # @HELP build onos-config benchmarks Docker image
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o build/atomix-raft-benchmarks/_output/bin/atomix-raft-benchmarks ./cmd/atomix-raft-benchmarks
	docker build . -f build/atomix-raft-benchmarks/Dockerfile -t atomix/atomix-raft-benchmarks:${ATOMIX_CONSUL_RAFT_NODE_VERSION}

push: # @HELP push atomix-consul-raft-node Docker image
	docker push atomix/atomix-consul-raft-node:${ATOMIX_CONSUL_RAFT_NODE_VERSION}
