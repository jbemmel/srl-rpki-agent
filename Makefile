LAST_COMMIT := $(shell sh -c "git log -1 --pretty=%h")
TODAY       := $(shell sh -c "date +%Y%m%d_%H%M")
TAG         := ${TODAY}.${LAST_COMMIT}
# HTTP_PROXY  := "http://proxy.lbs.alcatel-lucent.com:8000"

ifndef SR_LINUX_RELEASE
override SR_LINUX_RELEASE=latest
endif

.PHONY: build build-combined do-build frr build-srlinux

build: BASEIMG=srl/custombase
build: NAME=srl/rpki-agent
build: do-build

do-build:
	sudo DOCKER_BUILDKIT=0 docker build --build-arg SRL_RPKI_RELEASE=${TAG} \
	                  --build-arg http_proxy=${HTTP_PROXY} \
										--build-arg https_proxy=${HTTP_PROXY} \
										--build-arg SR_BASEIMG="${BASEIMG}" \
	                  --build-arg SR_LINUX_RELEASE="${SR_LINUX_RELEASE}" \
	                  -f ./Dockerfile -t ${NAME}:${TAG} .
	sudo docker tag ${NAME}:${TAG} ${NAME}:${SR_LINUX_RELEASE}

build-srlinux: BASEIMG=ghcr.io/nokia/srlinux
build-srlinux: NAME=srl/rpki-agent
build-srlinux: do-build

#
# This works but is more cumbersome, it rebuilds image every time base changes
#
# build-auto-frr: BASEIMG=srl/auto-config-v2
# build-auto-frr:	NAME=srl/auto-frr-demo
# build-auto-frr: do-build
