

.PHONY: clean build test cucumber

test:
	stable env ponyc -o bin test && ./bin/test

cucumber:
	pushd cucumber && bundle exec cucumber; popd

build:
	stable env ponyc -o bin posse

clean:
	rm bin/*
