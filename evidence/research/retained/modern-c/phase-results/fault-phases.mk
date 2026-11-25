.PHONY: phase1 phase2 phase3 phase4
phase1 phase2 phase3 phase4:
	@printf '%s\n' '$@' >> '$(RESULT_FILE)'
	@test -z '$(filter $@,$(FAIL_PHASES))'
