# Must be included *after* generate.mk, because we use GOHOSTOS and GOHOSTARCH defined there.

lint/go-dirs = $(OSS_HOME)

lint:
	@PS4=; set +ex; r=0; { \
		printf "$(CYN)==>$(END) Linting $(BLU)Go$(END)...\n"; \
		go_status=0; $(MAKE) golint || { go_status=$$?; r=$$go_status; }; \
		\
		printf "$(CYN)==>$(END) Linting $(BLU)Python$(END)...\n"; \
		py_status=0; $(MAKE) mypy || { py_status=$$?; r=$$py_status; }; \
		\
		printf "$(CYN)==>$(END) Linting $(BLU)Helm$(END)...\n"; \
		helm_status=0; $(MAKE) lint-chart || { helm_status=$$?; r=$$helm_status; }; \
		\
		printf "$(CYN)==>$(END) Linting $(BLU)Schemas$(END)...\n"; \
		schema_status=0; $(MAKE) schemalint || { schema_status=$$?; r=$$schema_status; }; \
		\
		set +x; \
		printf "$(CYN)==>$(END) $(BLU)Go$(END)      lint $$(if [[ $$go_status     == 0 ]]; then printf "$(GRN)OK"; else printf "$(RED)FAIL"; fi)$(END)\n"; \
		printf "$(CYN)==>$(END) $(BLU)Python$(END)  lint $$(if [[ $$py_status     == 0 ]]; then printf "$(GRN)OK"; else printf "$(RED)FAIL"; fi)$(END)\n"; \
		printf "$(CYN)==>$(END) $(BLU)Helm$(END)    lint $$(if [[ $$helm_status   == 0 ]]; then printf "$(GRN)OK"; else printf "$(RED)FAIL"; fi)$(END)\n"; \
		printf "$(CYN)==>$(END) $(BLU)Schemas$(END) lint $$(if [[ $$schema_status == 0 ]]; then printf "$(GRN)OK"; else printf "$(RED)FAIL"; fi)$(END)\n"; \
		set -x; \
		\
		exit $$r; \
	}
.PHONY: lint

golint: $(tools/golangci-lint)
	@PS4=; set -x; r=0; { \
		for dir in $(lint/go-dirs); do \
			(cd $$dir && $(tools/golangci-lint) run ./...) || r=$$?; \
		done; \
		exit $$r; \
	}
.PHONY: golint

schemalint: $(tools/schema-fmt)
	$(tools/schema-fmt) -d python/schemas/*/*.schema
.PHONY: schemalint

format: $(tools/golangci-lint) $(tools/schema-fmt)
	@PS4=; set -x; { \
		for dir in $(lint/go-dirs); do \
			(cd $$dir && $(tools/golangci-lint) run --fix ./...) || true; \
		done; \
	}
	$(tools/schema-fmt) -w python/schemas/*/*.schema
.PHONY: format
