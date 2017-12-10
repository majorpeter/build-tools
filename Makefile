# based on: https://spin.atomicobject.com/2016/08/26/makefile-c-projects/

PROJECT_NAME := InfinityClock
TARGET_EXEC ?= $(PROJECT_NAME).elf
TARGET_HEX ?= $(PROJECT_NAME).hex

BUILD_DIR ?= ./build
SRC_DIRS ?= application modules system

SRCS_ALL := $(shell find $(SRC_DIRS) -name *.cpp -or -name *.c -or -name *.s)
SRCS_EXCEPT := application/testmain.cpp \
			   modules/mprotocol-server/ServerSocketInterface.cpp
SRCS := $(filter-out $(SRCS_EXCEPT),$(SRCS_ALL))
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)
DEPS := $(OBJS:.o=.d)

COMMON_FLAGS ?= -mcpu=cortex-m3 -mthumb -Og -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -fno-move-loop-invariants -Wall -Wextra  -g3
DEFINES ?= DEBUG USE_FULL_ASSERT OS_USE_SEMIHOSTING TRACE OS_USE_TRACE_SEMIHOSTING_DEBUG STM32F10X_MD USE_STDPERIPH_DRIVER HSE_VALUE=8000000
DEFINE_FLAGS := $(addprefix -D,$(DEFINES))

INC_DIRS := $(shell find $(SRC_DIRS) -type d)
INC_FLAGS := $(addprefix -I,$(INC_DIRS))

CXX_FLAGS := $(COMMON_FLAGS) $(DEFINE_FLAGS) $(INC_FLAGS)
C_FLAGS := $(CXX_FLAGS) -std=gnu11
CPP_FLAGS := $(CXX_FLAGS) -std=gnu++11 -fabi-version=0 -fno-exceptions -fno-rtti -fno-use-cxa-atexit -fno-threadsafe-statics

LINKER_SCRIPTS := mem.ld libs.ld sections.ld
LINKER_SCRIPT_FOLDERS := "ldscripts"
LINKER_FLAGS := $(addprefix -T ,$(LINKER_SCRIPTS)) \
				$(addprefix -L,$(LINKER_SCRIPT_FOLDERS)) \
				-nostartfiles -Xlinker --gc-sections \
				-Wl,-Map,"$(BUILD_DIR)/$(PROJECT_NAME).map" --specs=nano.specs

## ELF (main output)
$(BUILD_DIR)/$(TARGET_EXEC): $(OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: C++ Linker'
	arm-none-eabi-g++ $(COMMON_FLAGS) $(LINKER_FLAGS) -o "$@" $(OBJS) $(LDFLAGS)
	@echo 'Finished building target: $@'
	@echo ' '

$(BUILD_DIR)/$(TARGET_HEX): $(BUILD_DIR)/$(TARGET_EXEC)
	@echo 'Invoking: Cross ARM GNU Create Flash Image'
	arm-none-eabi-objcopy -O ihex "$<"  "$@"
	@echo 'Finished building: $@'
	@echo ' '

# c source
$(BUILD_DIR)/%.c.o: %.c
	@echo 'Building file: $<'
	@echo 'Invoking: C Compiler'
	@$(MKDIR_P) $(dir $@)
	arm-none-eabi-gcc $(C_FLAGS) -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

# c++ source
$(BUILD_DIR)/%.cpp.o: %.cpp
	@echo 'Building file: $<'
	@echo 'Invoking: Cross ARM C++ Compiler'
	@$(MKDIR_P) $(dir $@)
	arm-none-eabi-g++ $(CPP_FLAGS) -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

.PHONY: all clean

all: $(BUILD_DIR)/$(TARGET_EXEC) $(BUILD_DIR)/$(TARGET_HEX)

clean:
	$(RM) -r $(BUILD_DIR)

-include $(DEPS)

MKDIR_P ?= mkdir -p
