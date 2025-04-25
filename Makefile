default: build

image := nbraun1/certbot:latest

# Trigger for GitHub Actions

git-release-tag:
	@read -p "Enter a git release tag in semver format: " TAG && \
	git tag "v$$TAG" && \
	git push origin "v$$TAG"

# For local testing purposes

build:
	@docker build -t $(image) .

# An "dive" installation is required. See https://github.com/wagoodman/dive
dive:
	@dive build -t $(image) .

run: build
	@docker run --rm $(image)

clean:
	@docker rmi -f $(image)
