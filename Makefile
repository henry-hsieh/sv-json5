# Makefile for sv-serde tests
# Uses Verilator 5.038

SV_SERDE_ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR := $(SV_SERDE_ROOT)/build
OBJ_DIR := $(BUILD_DIR)/obj_dir
CCACHE_DIR := $(BUILD_DIR)/ccache

VERILATOR = verilator
V_FLAGS = -Mdir $(OBJ_DIR) -j $(shell nproc) --binary -Wno-fatal

export SV_SERDE_ROOT
export CCACHE_DIR

COMMON_TESTS = test_smoke_common_result test_smoke_common_option
SERDE_TESTS = test_smoke_serde
JSON_TESTS = test_smoke_json_types test_smoke_json_deserialize test_smoke_json_serialize test_app_json_compliance test_app_json_value
JSON5_TESTS = test_smoke_json5_deserialize test_app_json5_compliance

.PHONY: all clean help

all: $(COMMON_TESTS) $(SERDE_TESTS) $(JSON_TESTS) $(JSON5_TESTS)

help:
	@echo "Available tests:"
	@echo "  Common package tests:"
	@echo "    make test_smoke_common_result   - Result type functional API tests"
	@echo "    make test_smoke_common_option  - Option type functional API tests"
	@echo "  Serde tests:"
	@echo "    make test_smoke_serde         - Serde trait tests"
	@echo "  JSON tests:"
	@echo "    make test_smoke_json_types    - JSON types smoke tests"
	@echo "    make test_smoke_json_deserialize - JSON deserialize tests"
	@echo "    make test_smoke_json_serialize  - JSON serialize tests"
	@echo "    make test_app_json_compliance - JSON compliance integration test (includes streaming)"
	@echo "    make test_app_json_value    - JSON value pattern demo (struct <-> json_value)"
	@echo "  JSON5 tests:"
	@echo "    make test_smoke_json5_deserialize - JSON5 extended features tests"
	@echo "    make test_app_json5_compliance - JSON5 compliance integration test (includes streaming)"
	@echo "  make all                      - Run all tests sequentially"
	@echo "  make clean                    - Remove build artifacts"

$(COMMON_TESTS): | $(BUILD_DIR)
	$(VERILATOR) $(V_FLAGS) -f $(SV_SERDE_ROOT)/src/common/common_pkg.f tests/$@.sv --top-module $@
	$(OBJ_DIR)/V$@

$(SERDE_TESTS): | $(BUILD_DIR)
	$(VERILATOR) $(V_FLAGS) -f $(SV_SERDE_ROOT)/src/common/common_pkg.f -f $(SV_SERDE_ROOT)/src/serde/serde_pkg.f tests/$@.sv --top-module $@
	$(OBJ_DIR)/V$@

$(JSON_TESTS): | $(BUILD_DIR)
	$(VERILATOR) $(V_FLAGS) -f $(SV_SERDE_ROOT)/src/json/json_pkg.f tests/$@.sv --top-module $@
	$(OBJ_DIR)/V$@

$(JSON5_TESTS): | $(BUILD_DIR)
	$(VERILATOR) $(V_FLAGS) -f $(SV_SERDE_ROOT)/src/json5/json5_pkg.f tests/$@.sv --top-module $@
	$(OBJ_DIR)/V$@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
