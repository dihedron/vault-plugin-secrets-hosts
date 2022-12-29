TOOL?=vault-plugin-secrets-hosts
TEST?=$$(go list ./... | grep -v /vendor/)
VETARGS?=-asmdecl -atomic -bool -buildtags -copylocks -methods -nilfunc -printf -rangeloops -shift -structtags -unsafeptr
EXTERNAL_TOOLS=\
	github.com/mitchellh/gox \
	github.com/golang/dep/cmd/dep
BUILD_TAGS?=${TOOL}
GOFMT_FILES?=$$(find . -name '*.go' | grep -v vendor)

# bin generates the releaseable binaries for this plugin
bin: fmtcheck generate
	@CGO_ENABLED=0 BUILD_TAGS='$(BUILD_TAGS)' sh -c "'$(CURDIR)/scripts/build.sh'"

default: dev

# dev creates binaries for testing Vault locally. These are put
# into ./bin/ as well as $GOPATH/bin.
dev: fmtcheck generate
	@CGO_ENABLED=0 BUILD_TAGS='$(BUILD_TAGS)' VAULT_DEV_BUILD=1 sh -c "'$(CURDIR)/scripts/build.sh'"

# test runs the unit tests and vets the code
test: fmtcheck generate
	CGO_ENABLED=0 VAULT_TOKEN= VAULT_ACC= go test -tags='$(BUILD_TAGS)' $(TEST) $(TESTARGS) -count=1 -timeout=20m -parallel=4

testcompile: fmtcheck generate
	@for pkg in $(TEST) ; do \
		go test -v -c -tags='$(BUILD_TAGS)' $$pkg -parallel=4 ; \
	done

# generate runs `go generate` to build the dynamically generated
# source files.
generate:
	go generate $(go list ./... | grep -v /vendor/)

# bootstrap the build by downloading additional tools
bootstrap:
	@for tool in  $(EXTERNAL_TOOLS) ; do \
		echo "Installing/Updating $$tool" ; \
		go get -u $$tool; \
	done

fmtcheck:
	@sh -c "'$(CURDIR)/scripts/gofmtcheck.sh'"

fmt:
	gofmt -w $(GOFMT_FILES)

proto:
	protoc --go_out=. --go_opt=paths=source_relative *.proto

.PHONY: bin default generate test vet bootstrap fmt fmtcheck

#
# CUSTOM
#

.PHONY: clean
clean:
	@rm -rf pkg bin

# compute the plugin's SHA-256 sum
.PHONY: shasum
shasum: bin
	$(eval SHA256=$(shell sha256sum bin/vault-plugin-secrets-hosts | cut -d ' ' -f1))
	@echo "plugin's SHA-256 sum is $(SHA256)"

# register the plugin to vault (using its SHA-256 sum)
.PHONY: register
register: bin
	@mkdir -p _tests/data/plugins/
	$(eval SHA256=$(shell sha256sum bin/vault-plugin-secrets-hosts | cut -d ' ' -f1))
	@mv bin/vault-plugin-secrets-hosts _tests/data/plugins/	
	@vault plugin register -sha256=$(SHA256) secret vault-plugin-secrets-hosts

# enable the registered plugin as a secrets engine in vault
.PHONY: enable
enable: register # maybe add disable first?
	@vault secrets enable -path=hosts vault-plugin-secrets-hosts

# enable the registered plugin as a secrets engine in vault
.PHONY: disable
disable:
	@vault secrets disable hosts