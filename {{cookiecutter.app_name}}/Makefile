# Copyright IBM Corp All Rights Reserved.
# Copyright London Stock Exchange Group All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
#
# This makefile defines the following targets
## 0. vars

BASE_VERSION = 1.1.1
PREV_VERSION = 1.1.0
BASEIMAGE_RELEASE=0.4.6

GIT_COMMIT=$(shell git rev-parse HEAD)
GIT_DIRTY=$(shell test -n "`git status --porcelain`" && echo "+CHANGES" || true)


# Allow to build as a submodule setting the main project to
# the PROJECT_NAME env variable, for example,
# export PROJECT_NAME={{ cookiecutter.github_username }}/{{ cookiecutter.app_name }}-test
ifeq ($(PROJECT_NAME),true)
PROJECT_NAME = $(PROJECT_NAME)/{{ cookiecutter.app_name }}
else
PROJECT_NAME = {{ cookiecutter.github_username }}/{{ cookiecutter.app_name }}
endif
IS_RELEASE = false
EXPERIMENTAL ?= true

ifeq ($(EXPERIMENTAL),true)
GO_TAGS += experimental
endif

ifneq ($(IS_RELEASE),true)
EXTRA_VERSION ?= snapshot-$(shell git rev-parse --short HEAD)
PROJECT_VERSION=$(BASE_VERSION)-$(EXTRA_VERSION)
else
PROJECT_VERSION=$(BASE_VERSION)
endif

PKGNAME = github.com/$(PROJECT_NAME)
CGO_FLAGS = CGO_CFLAGS=" "
MARCH=$(shell go env GOOS)-$(shell go env GOARCH)

# check depend exec exist.
EXECUTABLES = go docker git curl
K := $(foreach exec,$(EXECUTABLES),\
    $(if $(shell which $(exec)),some string,$(error "No $(exec) in PATH: Check dependencies")))

# No sense rebuilding when non production code is changed
PROJECT_FILES = $(shell git ls-files  | grep -v ^test | grep -v ^unit-test | \
    grep -v ^docs | grep -v _test.go$ | grep -v .md$ | \
    grep -v ^.git | grep -v ^examples | grep -v ^devenv | grep -v .png$ | \
    grep -v ^LICENSE )

RELEASE_PLATFORMS = windows-amd64 linux-amd64

pkgmap.{{ cookiecutter.app_name }}           := $(PKGNAME)/{{ cookiecutter.app_name }}

include docker-env.mk

############ Help ######################
help:
	@echo 'Management commands for {{cookiecutter.app_name}}:'
	@echo 'Usage:'
	@echo '    make all (default) - builds all targets and runs all tests/checks'
	@echo '    make checks - runs all tests/checks'
	@echo '    make desk-check - runs linters and verify to test changed packages'
	@echo '    make build/bin/* - runs go install build app bin.'
	@echo '    make release - builds release packages for the host platform'
	@echo '    make release-all - builds release packages for all target platforms'
	@echo '    make unit-test - runs the go-test based unit tests'
	@echo '    make verify - runs unit tests for only the changed package tree'
	@echo '    make profile - runs unit tests for all packages in coverprofile mode (slow)'
	@echo '    make behave - runs the behave test'
	@echo '    make behave-deps - ensures pre-requisites are available for running behave manually'
	@echo '    make gotools - installs go tools like golint'
	@echo '    make linter - runs all code checks'
	@echo '    make license - checks go source files for Apache license header'
	@echo '    make docker[-clean] - ensures all docker images are available[/cleaned]'
	@echo '    make docker-list - generates a list of docker images that 'make docker' produces'
	@echo '    make clean - cleans the build area'
	@echo '    make clean-all - superset of 'clean' that also removes persistent state'
	@echo '    make dist-clean - clean release packages for all target platforms'
	@echo '    make unit-test-clean - cleans unit test state (particularly from docker)'
	@echo '    make basic-checks - performs basic checks like license, spelling and linter'
	@echo '    make docker-thirdparty - pulls thirdparty images (kafka,zookeeper,couchdb)'
	@echo



#################################################################################
## Rules

all: checks

############### Testing ###############
checks: license spelling linter unit-test behave
basic-checks: license spelling linter
desk-check: license spelling linter verify behave

## 0. license
.PHONY: license
license:
	@scripts/check_license.sh

## 1. spelling
.PHONY: spelling
spelling:
	@scripts/check_spelling.sh

## 2. linter
linter: buildenv
	@echo "LINT: Running code checks.."
	@$(DRUN) $(DOCKER_NS)/{{ cookiecutter.app_name }}-buildenv:$(DOCKER_TAG) ./scripts/golinter.sh

## 3. unit-test
unit-test: unit-test-clean testenv docker-thirdparty
	cd unit-test && docker-compose up --abort-on-container-exit --force-recreate && docker-compose down

## 4. behave
behave-deps: docker docker-thirdparty
behave: behave-deps
	@echo "Running behave tests"
	@cd /test/regressive/bddtests; behave $(BEHAVE_OPTS)

## 5. others

verify: unit-test-clean testenv
	cd unit-test && JOB_TYPE=VERIFY docker-compose up --abort-on-container-exit --force-recreate && docker-compose down

profile: unit-test-clean testenv
	cd unit-test && JOB_TYPE=PROFILE docker-compose up --abort-on-container-exit --force-recreate && docker-compose down

### 6. envs

buildenv:
	@echo "TODO: Add docker build images for buildenv"

testenv: docker-thirdparty
	@echo "TODO: add test docker iages for testenv"

########### Tools ###############
.PHONY: gotools
gotools:
	mkdir -p build/bin
	cd gotools && $(MAKE) install BINDIR=$(GOPATH)/bin

get-deps:
	dep ensure

########## Changelog #############
changelog:
	./scripts/changelog.sh v$(PREV_VERSION) v$(BASE_VERSION)

############ Dist ##############
.PHONY: dist
dist: dist-clean dist/$(MARCH)

dist-all: dist-clean $(patsubst %,dist/%, $(RELEASE_PLATFORMS))

dist/%: release/%
	mkdir -p release/$(@F)/config
	cp -r sampleconfig/*.yaml release/$(@F)/config
	cd release/$(@F) && tar -czvf {{ cookiecutter.github_username }}-{{ cookiecutter.app_name }}-$(@F).$(PROJECT_VERSION).tar.gz *

############ Build ##################
# TODO: docker image build begins
docker: $(patsubst %,build/image/%/$(DUMMY), $(IMAGES))

# Pull thirdparty docker images based on the latest baseimage release version
.PHONY: docker-thirdparty
docker-thirdparty:
	docker pull $(BASE_DOCKER_NS)/{{ cookiecutter.app_name }}-mysql:$(BASE_DOCKER_TAG)
	docker tag $(BASE_DOCKER_NS)/{{ cookiecutter.app_name }}-mysql:$(BASE_DOCKER_TAG) $(DOCKER_NS)/{{ cookiecutter.app_name }}-mysql
	@echo "TODO Add depends third party docker imgage, inc mysql, kafka."

%-docker-list:
	$(eval TARGET = ${patsubst %-docker-list,%,${@}})
	@echo $(DOCKER_NS)/{{ cookiecutter.app_name }}-$(TARGET):$(DOCKER_TAG)

docker-list: $(patsubst %,%-docker-list, $(IMAGES))


### 1 docker

# We (re)build a package within a docker context but persist the $GOPATH/pkg
# directory so that subsequent builds are faster
build/docker/bin/%: $(PROJECT_FILES)
	$(eval TARGET = ${patsubst build/docker/bin/%,%,${@}})
	@echo "Building $@"
	@mkdir -p build/docker/bin build/docker/$(TARGET)/pkg
	@$(DRUN) \
		-v $(abspath build/docker/bin):/opt/gopath/bin \
		-v $(abspath build/docker/$(TARGET)/pkg):/opt/gopath/pkg \
		$(BASE_DOCKER_NS)/{{ cookiecutter.app_name }}-baseimage:$(BASE_DOCKER_TAG) \
		go install -tags "$(GO_TAGS)" -ldflags "$(DOCKER_GO_LDFLAGS)" $(pkgmap.$(@F))
	@touch $@

build/docker/gotools: gotools/Makefile
	@mkdir -p $@/bin $@/obj
	@$(DRUN) \
		-v $(abspath $@):/opt/gotools \
		-w /opt/gopath/src/$(PKGNAME)/gotools \
		$(BASE_DOCKER_NS)/{{ cookiecutter.app_name }}-baseimage:$(BASE_DOCKER_TAG) \
		make install BINDIR=/opt/gotools/bin OBJDIR=/opt/gotools/obj

### 2 bin

build/bin/%: $(PROJECT_FILES)
	@mkdir -p $(@D)
	@echo "$@"
	$(CGO_FLAGS) GOBIN=$(abspath $(@D)) go install -tags "$(GO_TAGS)" -ldflags "$(GO_LDFLAGS)" $(pkgmap.$(@F))
	@echo "Binary available as $@"
	@touch $@

### 3 image

# payload definitions
build/image/buildenv/payload:   build/gotools.tar.bz2
build/image/testenv/payload:    build/sampleconfig.tar.bz2
build/image/tools/payload:      build/sampleconfig.tar.bz2
build/image/%/payload:
	mkdir -p $@
	cp $^ $@

.PRECIOUS: build/image/%/Dockerfile
build/image/%/Dockerfile: images/%/Dockerfile.in
	@cat $< \
		| sed -e 's/_BASE_NS_/$(BASE_DOCKER_NS)/g' \
		| sed -e 's/_NS_/$(DOCKER_NS)/g' \
		| sed -e 's/_BASE_TAG_/$(BASE_DOCKER_TAG)/g' \
		| sed -e 's/_TAG_/$(DOCKER_TAG)/g' \
		> $@
	@echo LABEL $(BASE_DOCKER_LABEL).version=$(PROJECT_VERSION) \\>>$@
	@echo "     " $(BASE_DOCKER_LABEL).base.version=$(BASEIMAGE_RELEASE)>>$@

build/image/%/$(DUMMY): Makefile build/image/%/payload build/image/%/Dockerfile
	$(eval TARGET = ${patsubst build/image/%/$(DUMMY),%,${@}})
	@echo "Building docker $(TARGET)-image"
	$(DBUILD) -t $(DOCKER_NS)/{{ cookiecutter.app_name }}-$(TARGET) $(@D)
	docker tag $(DOCKER_NS)/{{ cookiecutter.app_name }}-$(TARGET) $(DOCKER_NS)/{{ cookiecutter.app_name }}-$(TARGET):$(DOCKER_TAG)
	@touch $@

build/image/testenv/$(DUMMY): build/image/buildenv/$(DUMMY)

### 4 others
build/gotools.tar.bz2: build/docker/gotools
	(cd $</bin && tar -jc *) > $@

build/sampleconfig.tar.bz2: $(shell find sampleconfig -type f)
	(cd sampleconfig && tar -jc *) > $@

build/%.tar.bz2:
	@echo "Creating $@"
	@tar -jc $^ > $@

############ Release ##################

# builds release packages for the host platform
release: $(patsubst %,release/%, $(MARCH))

# builds release packages for all target platforms
release-all: $(patsubst %,release/%, $(RELEASE_PLATFORMS))

release/%: GO_LDFLAGS=-X $(pkgmap.$(@F))/metadata.Version=$(PROJECT_VERSION)

release/windows-amd64: GOOS=windows
release/windows-amd64: GO_TAGS+= nopkcs11
release/windows-amd64: $(patsubst %,release/windows-amd64/bin/%, $(RELEASE_PKGS)) release/windows-amd64/install

release/linux-amd64: GOOS=linux
release/linux-amd64: GO_TAGS+= nopkcs11
release/linux-amd64: $(patsubst %,release/linux-amd64/bin/%, $(RELEASE_PKGS)) release/linux-amd64/install

release/%-amd64: DOCKER_ARCH=x86_64
release/%-amd64: GOARCH=amd64
release/linux-%: GOOS=linux

release/%/install: $(PROJECT_FILES)
	mkdir -p $(@D)/bin
	@cat $(@D)/../templates/get-docker-images.in \
		| sed -e 's/_NS_/$(DOCKER_NS)/g' \
		| sed -e 's/_ARCH_/$(DOCKER_ARCH)/g' \
		| sed -e 's/_VERSION_/$(PROJECT_VERSION)/g' \
		| sed -e 's/_BASE_DOCKER_TAG_/$(BASE_DOCKER_TAG)/g' \
		> $(@D)/bin/get-docker-images.sh
		@chmod +x $(@D)/bin/get-docker-images.sh

################ Clean #######################

docker-clean: $(patsubst %,%-docker-clean, $(IMAGES))

.PHONY: clean
clean: docker-clean unit-test-clean release-clean
	-@rm -rf build ||:

.PHONY: clean-all
clean-all: clean gotools-clean dist-clean
	-@rm -rf /var/{{ cookiecutter.github_username }}/* ||:

.PHONY: dist-clean
dist-clean:
	-@rm -rf release/windows-amd64/{{ cookiecutter.github_username }}-{{ cookiecutter.app_name }}-windows-amd64.$(PROJECT_VERSION).tar.gz ||:
	-@rm -rf release/linux-amd64/{{ cookiecutter.github_username }}-{{ cookiecutter.app_name }}-linux-amd64.$(PROJECT_VERSION).tar.gz ||:

%-release-clean:
	$(eval TARGET = ${patsubst %-release-clean,%,${@}})
	-@rm -rf release/$(TARGET)

release-clean: $(patsubst %,%-release-clean, $(RELEASE_PLATFORMS))

.PHONY: unit-test-clean
unit-test-clean:
	cd unit-test && docker-compose down

.PHONY: gotools-clean
gotools-clean:
	cd gotools && $(MAKE) clean


