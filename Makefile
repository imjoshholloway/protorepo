SHELL := /usr/bin/env bash -o pipefail

# This allows switching between i.e a Docker container and your local setup without overwriting.
CACHE_BASE := .cache

# The branch to use for buf break check
GIT_BRANCH := mainline

# The base directory to use to find *.proto files
PROTOS_BASE_DIR := proto
# The base directory for code generation of proto files
PROTOS_OUT_DIR := .

# The base directory for code generation of swagger files
SWAGGER_OUT_DIR := .

# This controls the remote HTTPS git location to compare against for breaking changes in CI.
#
# Most CI providers only clone the branch under test and to a certain depth, so when
# running buf check breaking in CI, it is generally preferable to compare against
# the remote repository directly.
#
# Basic authentication is available, see https://buf.build/docs/inputs#https for more details.
HTTPS_GIT := https://github.com/imjoshholloway/protorepo.git

# This controls the version of buf to install and use.
BUF_VERSION := 0.19.1
PROTOC_VERSION := 3.12.3
PROTOC_GEN_GO_VERSION := v1.4.2
PROTOC_GEN_GRPC_GATEWAY_VERSION := v1.14.6
PROTOC_GEN_SWAGGER_VERSION := v1.14.6
PROTODEP_VERSION := 0.0.9

### Everything below this line is meant to be static, i.e. only adjust the above variables. ###

UNAME_OS := $(shell uname -s)
UNAME_ARCH := $(shell uname -m)
UNAME_PLATFORM := $(shell uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/osx/')

CACHE := $(CACHE_BASE)/$(UNAME_OS)/$(UNAME_ARCH)
# The location where buf will be installed.
CACHE_BIN := $(CACHE)/bin
# Marker files are put into this directory to denote the current version of binaries that are installed.
CACHE_VERSIONS := $(CACHE)/versions
# We do some temporary work here
CACHE_TMP := $(CACHE_BASE)/tmp

# The files to run protoc on
EXCLUDE := -path ./third_party -prune -o
PROTO_DEFS := $(shell find $(PROTOS_BASE_DIR) $(EXCLUDE) -type f -name '*.proto' -print)
PROTO_GOS := $(patsubst $(PROTOS_BASE_DIR)/%.proto,$(PROTOS_OUT_DIR)/%.pb.go,$(PROTO_DEFS))
PROTO_GOS_GRPC := $(patsubst %.pb.go,%.pb.gw.go,$(PROTO_GOS))

# Plugins string for go builds (must end in ':')
PROTOC_GO_PLUGINS := plugins=grpc:

# Options string appended to go build command (optional, obviously)
PROTOC_GO_OPT := --go_out=$(PROTOC_GO_PLUGINS)$(PROTOS_OUT_DIR) --go_opt=paths=source_relative

# Options string appended to grpc-gateway build command (optional)
PROTOC_GRPC_GATEWAY_OPT := --grpc-gateway_out=logtostderr=true,paths=source_relative:$(PROTOS_OUT_DIR)

# Options string appended to swagger build command (optional)
PROTOC_SWAGGER_OPT := --swagger_out=logtostderr=true:$(SWAGGER_OUT_DIR)

# Go tools require that this be set
ifndef GOPATH
	export GOPATH=$(shell go env GOPATH)
endif

# Update the $PATH so we can use buf and protoc directly
export PATH := $(abspath $(CACHE_BIN)):$(abspath $(GOPATH)/bin):$(PATH)
# Update GOBIN to point to CACHE_BIN for source installations
export GOBIN := $(abspath $(CACHE_BIN))
# This is needed to allow versions to be added to Golang modules with go get
export GO111MODULE := on

# BUF points to the marker file for the installed version.
#
# If BUF_VERSION is changed, the binary will be re-downloaded.
BUF := $(CACHE_VERSIONS)/buf/$(BUF_VERSION)
$(BUF):
	@rm -f $(CACHE_BIN)/buf
	@mkdir -p $(CACHE_BIN)
	curl -sSL \
		"https://github.com/bufbuild/buf/releases/download/v$(BUF_VERSION)/buf-$(UNAME_OS)-$(UNAME_ARCH)" \
		-o "$(CACHE_BIN)/buf"
	chmod +x "$(CACHE_BIN)/buf"
	@rm -rf $(dir $(BUF))
	@mkdir -p $(dir $(BUF))
	@touch $(BUF)

PROTOC := $(CACHE_VERSIONS)/protoc/$(PROTOC_VERSION)
$(PROTOC):
	@rm -f $(CACHE_TMP)/protoc.zip
	@rm -f $(CACHE_BIN)/protoc
	@mkdir -p $(CACHE_TMP)
	@mkdir -p $(CACHE_BIN)
	curl -sSL \
		"https://github.com/protocolbuffers/protobuf/releases/download/v$(PROTOC_VERSION)/protoc-$(PROTOC_VERSION)-$(UNAME_PLATFORM)-$(UNAME_ARCH).zip" \
		-o "$(CACHE_TMP)/protoc.zip"
	unzip $(CACHE_TMP)/protoc.zip bin/protoc -d $(CACHE)
	chmod +x "$(CACHE_BIN)/protoc"
	@rm -rf $(dir $(PROTOC))
	@mkdir -p $(dir $(PROTOC))
	@touch $(PROTOC)

PROTOC_GEN_GO := $(CACHE_VERSIONS)/protoc-gen-go/$(PROTOC_GEN_GO_VERSION)
$(PROTOC_GEN_GO):
	$(eval _TMP := $(shell mktemp -d))
	cd $(_TMP); \
	  go get github.com/golang/protobuf/protoc-gen-go@$(PROTOC_GEN_GO_VERSION)
	@rm -rf $(_TMP)
	@rm -rf $(dir $(PROTOC_GEN_GO))
	@mkdir -p $(dir $(PROTOC_GEN_GO))
	@touch $(PROTOC_GEN_GO)

PROTOC_GEN_GRPC_GATEWAY := $(CACHE_VERSIONS)/protoc-gen-grpc-gateway/$(PROTOC_GEN_GRPC_GATEWAY_VERSION)
$(PROTOC_GEN_GRPC_GATEWAY):
	$(eval _TMP := $(shell mktemp -d))
	cd $(_TMP); \
	  go get github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway@$(PROTOC_GEN_GRPC_GATEWAY_VERSION)
	@rm -rf $(_TMP)
	@rm -rf $(dir $(PROTOC_GEN_GRPC_GATEWAY))
	@mkdir -p $(dir $(PROTOC_GEN_GRPC_GATEWAY))
	@touch $(PROTOC_GEN_GRPC_GATEWAY)

PROTOC_GEN_SWAGGER := $(CACHE_VERSIONS)/protoc-gen-swagger/$(PROTOC_GEN_SWAGGER_VERSION)
$(PROTOC_GEN_SWAGGER):
	$(eval _TMP := $(shell mktemp -d))
	cd $(_TMP); \
	  go get github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger@$(PROTOC_GEN_SWAGGER_VERSION)
	@rm -rf $(_TMP)
	@rm -rf $(dir $(PROTOC_GEN_SWAGGER))
	@mkdir -p $(dir $(PROTOC_GEN_SWAGGER))
	@touch $(PROTOC_GEN_SWAGGER)

PROTODEP := $(CACHE_VERSIONS)/protodep/$(PROTODEP_VERSION)
$(PROTODEP):
	$(eval _TMP := $(shell mktemp -d))
	cd $(_TMP); \
	  go get github.com/stormcat24/protodep@$(PROTODEP_VERSION)
	@rm -rf $(_TMP)
	@rm -rf $(dir $(PROTODEP))
	@mkdir -p $(dir $(PROTODEP))
	@touch $(PROTODEP)

# deps allows us to install deps without running any checks.
.PHONY: deps
deps: $(BUF) $(PROTOC) $(PROTOC_GEN_GO) $(PROTOC_GEN_GRPC_GATEWAY) $(PROTOC_GEN_SWAGGER) $(PROTODEP)

# update proto dependencies using protodep
protodeps: $(PROTODEP)
	# We use a fake ssh key here to force HTTP/HTTPS
	protodep up -f -i fakesshkey

# buf-lint performs linting using buf
buf-lint: $(BUF)
	buf check lint

# buf-local is what we run when testing locally.
# This does breaking change detection against our local git repository.
.PHONY: buf-local
buf-local: $(BUF) buf-lint
	buf check breaking --against-input '.git#branch=$(GIT_BRANCH)'

# buf-breaking does breaking change detection against our remote HTTPS git repository.
.PHONY: buf-breaking
buf-breaking: $(BUF)
	buf check breaking --against-input "$(HTTPS_GIT)#branch=$(GIT_BRANCH)"

# protos triggers generation for all protos
.PHONY: protos
protos: $(BUF) $(PROTO_GOS_GRPC)

# regenerate the *.pb.go files whenever the source protos change
# regenerate the *.pb.gw.go files whenever the source protos change
# regenerate the *.swagger.json files whenever the source protos change
$(PROTO_GOS) $(PROTO_GOS_GRPC): $(PROTO_DEFS)
	@echo "🤖 Generating ${@} from ${<}"
	$(eval PROTO := $(patsubst $(PROTOS_BASE_DIR)/%.proto,%.proto,${<}))
	buf image build -o - | protoc --descriptor_set_in=/dev/stdin $(PROTOC_GO_OPT) $(PROTOC_GRPC_GATEWAY_OPT) $(PROTOC_SWAGGER_OPT) $(PROTO)
