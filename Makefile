.PHONY: all deploy preview build plantuml

ROOT_DIR:=$(realpath $(shell dirname $(firstword $(MAKEFILE_LIST))))

all: build deploy

plantuml:
	plantuml $(ROOT_DIR)/docs/posts/*.puml -o $(ROOT_DIR)/docs/media

build: plantuml
	mkdocs build

deploy: build
	firebase deploy --only hosting\:partho-9a092

preview: build
	mkdocs serve

