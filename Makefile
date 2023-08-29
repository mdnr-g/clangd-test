.PHONY: all build build-container cmake format format-linux flash-stlink flash-jlink format-container shell image build-container clean clean-image clean-all
############################### Native Makefile ###############################

BUILD_DIR ?= build
# FIRMWARE := $(shell ls -t $(BUILD_DIR)/*.bin | head -n1) 
BUILD_TYPE ?= Debug
PLATFORM = $(if $(OS),$(OS),$(shell uname -s))
PROJECT_NAME ?= 8ch

BUILD_SYSTEM ?= Unix Makefiles

all: build 

# update_bin: build
# 	$(eval FIRMWARE := $(shell ls -t $(BUILD_DIR)/*.bin | head -n1))
# 	rm -rf $(BIN_DIR)/$(PROJECT_NAME)* && cp $(FIRMWARE) $(BIN_DIR)

build: cmake
	$(MAKE) -C $(BUILD_DIR) --no-print-directory

cmake: $(BUILD_DIR)/Makefile

$(BUILD_DIR)/Makefile: CMakeLists.txt
	cmake \
		-G "$(BUILD_SYSTEM)" \
		-B$(BUILD_DIR) \
		-DPROJECT_NAME=$(PROJECT_NAME) \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_TOOLCHAIN_FILE=gcc-arm-none-eabi.cmake \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
		-DDUMP_ASM=OFF \
		# -DLANE_ID=${LANE_ID} \
		# -DDEVICE_ID=${DEVICE_ID} \

# Formats all user modified source files (add ones that are missing)
SRCS := $(shell find . -iname '*.[ch]' ! -path './libopencm3-f4/*' ! -path './build/*') 
format: $(addsuffix .format,$(SRCS))
%.format: %
	clang-format -i $<

# Formats all CubeMX generated sources to unix style - removes \r from line endings
# Add any new directories, like Middlewares and hidden files
# HIDDEN_FILES := .mxproject .project .cproject
# FOUND_HIDDEN_FILES := $(shell for f in $(HIDDEN_FILES);do if [[ -e $$f ]]; then echo $$f;fi; done)
# FORMAT_LINUX := $(shell find Core Drivers -name '*' -type f; find . -name '*.ioc') $(FOUND_HIDDEN_FILES)

format-linux: $(addsuffix .format-linux,$(FORMAT_LINUX))
%.format-linux: %
	$(if $(filter $(PLATFORM),Linux),dos2unix -q $<,)

# Device specific!
# DEVICE ?= STM32F103RB

flash-st: update_bin
	st-flash --reset write $(FIRMWARE) 0x08000000

$(BUILD_DIR)/jlink-script:
	touch $@
	@echo device $(DEVICE) > $@
	@echo si 1 >> $@
	@echo speed 4000 >> $@
	@echo loadfile $(FIRMWARE),0x08000000 >> $@
	@echo -e "r\ng\nqc" >> $@

flash-jlink: build | $(BUILD_DIR)/jlink-script
	JLinkExe -commanderScript $(BUILD_DIR)/jlink-script

clean:
	rm -rf $(BUILD_DIR)
