MAIN_PACKAGE_PATH := ./cmd/server
BINARY_NAME := server

.PHONY: help
help: ## Help command for makefile
	@echo "Usage: make [command]"
		@sed -n 's/^\([a-zA-Z_-]*\):.*##\(.*\)/\1: \2/p' $(MAKEFILE_LIST) | column -t -s ':'

.PHONY: no-dirty
no-dirty: ## Check if there are uncommitted changes
	git diff --exit-code


.PHONY: tidy
tidy: ## format code and tidy modfile
	go fmt ./...
	go mod tidy -v


.PHONY: audit
audit: ## run audit checks
	go test -v ./...
	go mod verify
	go vet ./...
	go run honnef.co/go/tools/cmd/staticcheck@latest -checks=all,-ST1000,-U1000 ./...
	go run golang.org/x/vuln/cmd/govulncheck@latest ./...
	go test -race -buildvcs -vet=off ./...

.PHONY: test
test: ## run all tests
	go test -v -race -buildvcs ./...

.PHONY: test-cover
test-cover: ## run all tests and display coverage
	go test -v -race -buildvcs -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out

.PHONY: build
build: ## build the application
	# Include additional build steps, like TypeScript, SCSS or Tailwind compilation here...
	go build -o=./bin/${BINARY_NAME} ${MAIN_PACKAGE_PATH}

.PHONY: run
dev: ## run the  application
	go run ${MAIN_PACKAGE_PATH}

.PHONY: push
push: tidy audit no-dirty ## push changes to the remote Git repository
	git push

.PHONY: deploy
deploy: ## deploy the application to production
	GOOS=linux GOARCH=amd64 go build -ldflags='-s' -o=./bin/linux_amd64/${BINARY_NAME} ${MAIN_PACKAGE_PATH}
# upx -5 ./bin/linux_amd64/${BINARY_NAME}
# Include additional deployment steps here...


