install: ## Install the components needed
	python3 -m venv venv
	venv/bin/pip install -r requirements.txt
	venv/bin/pre-commit install

# inspired from https://gist.github.com/sjparkinson/f0413d429b12877ecb087c6fc30c1f0a

.DEFAULT_GOAL := help
help: ## Show this help
	@echo "Use 'make [command]' to run one of these commands:"
	@echo ""
	@fgrep --no-filename "##" ${MAKEFILE_LIST} | head -n '-1' | sed 's/\:.*\#/\: \#/g' | column -s ':#' -t -c 2
	@echo ""
	@echo "Open this Makefile to see what each command does."