#
# Examples:
#   make test tests='"notice / raw"'
#     build and run the pony tests, filtering for only those whos name
#     starts with "notice / raw"
#
#   make cucumber tests='features/connect.feature:38'
#     build the main executable, and run cucumber tests matching
#     the ghirkin filter "features/connect.feature:38"
#

.PHONY: clean build test cucumber all

test:
	stable env ponyc -o bin test && ./bin/test --only=$(tests)

cucumber: build
	pushd cucumber && bundle exec cucumber $(tests); popd

build:
	stable env ponyc -o bin posse

clean:
	rm -f bin/*

all: clean test build cucumber
