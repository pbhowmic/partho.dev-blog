.PHONY: all deploy preview build

all: build deploy

build:
	mkdocs build

deploy: build
	firebase deploy --only hosting\:partho-9a092

preview: build
	mkdocs serve
    