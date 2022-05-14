default: help

REGISTRY ?=
DOCKER_ID ?= nbraun1
REPOSITORY ?= certbot
TAG ?=
PASSWORD_FILE ?= .docker-password.txt

ifdef REGISTRY
image := $(REGISTRY)/$(DOCKER_ID)/$(REPOSITORY)
else
image := $(DOCKER_ID)/$(REPOSITORY)
endif

image_with_tag := $(image):$(TAG)
image_with_latest_tag := $(image):latest

.PHONY: help
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Print this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: all
all: git-tag git-tag-push docker-clean docker-login docker-build docker-tag docker-push docker-logout ## Run the complete release process

# git targets

.PHONY: git-tag
git-tag: check-tag ## Create a Git tag
	@echo create git tag
	@git tag $(TAG)

.PHONY: git-tag-push
git-tag-push: check-tag ## Push a Git tag
	@echo push git tag
	@git push origin $(TAG)

# docker targets

.PHONY: docker-clean
docker-clean: check-tag ## Remove each of our built Docker images
	@echo remove built images
	@docker rmi $(image_with_tag) 2>/dev/null || true
	@docker rmi $(image_with_latest_tag) 2>/dev/null || true

.PHONY: docker-login
docker-login: ## Perform login to Docker registry
ifdef PASSWORD_FILE
ifeq ($(shell test -f $(PASSWORD_FILE) && echo -n yes), yes)
	@echo perform login
	@cat $(PASSWORD_FILE) | base64 -d | docker login -u $(DOCKER_ID) --password-stdin $(REGISTRY)
else
	$(error $(PASSWORD_FILE) not exists)
endif
else
	$(error PASSWORD_FILE variable is undefined)
endif

.PHONY: docker-build
docker-build: check-tag ## Build a new Docker image
	@echo build $(image_with_tag)
	@docker build -t $(image_with_tag) .

.PHONY: docker-tag
docker-tag: check-tag ## Tag a Docker image
	@echo tag image $(image_with_tag) to $(image_with_latest_tag)
	@docker tag $(image_with_tag) $(image_with_latest_tag)

.PHONY: docker-push
docker-push: check-tag ## Push a Docker image
	@echo push $(image_with_tag) and $(image_with_latest_tag)
	@docker push $(image_with_tag)
	@docker push $(image_with_latest_tag)

.PHONY: docker-logout
docker-logout: ## Perform logout from Docker registry
	@echo perform logout
	@docker logout $(REGISTRY)

# utility targets

.PHONY: check-tag
check-tag:
ifndef TAG
	$(error TAG variable is undefined)
endif