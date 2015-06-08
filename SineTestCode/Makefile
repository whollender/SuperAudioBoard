# The name of your project (used to name the compiled .hex file)
TARGET = sine_test

# configurable options
OPTIONS = -DF_CPU=48000000 -DLAYOUT_US_ENGLISH -DUSB_SERIAL

# options needed by many Arduino libraries to configure for Teensy 3.0
OPTIONS += -D__MK20DX256__ 

#************************************************************************
# ARM CMSIS Lib stuff
#  Section added for ARM CMSIS library
#************************************************************************

# Paths
CMSISPATH = ../tools/CMSIS-SP-00300-r3p2-00rel1/CMSIS

# Don't use absolute paths.  They create major headaches (cygwin paths
# don't work, and windows paths include :'s, which break the dependency
# *.d files)
CMSIS_INCL = $(CMSISPATH)/Include
CMSIS_LIB_PATH = $(CMSISPATH)/Lib/GCC

# Library (use cortex-M4 little-endian lib)
CMSIS_LIB_NAME = arm_cortexM4l_math

# Define for Cortex-M4
OPTIONS += -DARM_MATH_CM4


#************************************************************************
# Location of Teensyduino utilities, Toolchain, and Arduino Libraries.
# To use this makefile without Arduino, copy the resources from these
# locations and edit the pathnames.  The rest of Arduino is not needed.
#************************************************************************

# path location for Teensy Loader, teensy_post_compile and teensy_reboot
TOOLSPATH = ../tools   # on Linux

# path location for the arm-none-eabi compiler
COMPILERPATH = ../tools/arm-none-eabi/bin

#************************************************************************
# Settings below this point usually do not need to be edited
#************************************************************************

# CPPFLAGS = compiler options for C and C++
CPPFLAGS = -Wall -g -Os -mcpu=cortex-m4 -mthumb -nostdlib -MMD $(OPTIONS) -I.
CPPFLAGS += -I$(CMSIS_INCL)

# compiler options for C++ only
CXXFLAGS = -std=gnu++0x -felide-constructors -fno-exceptions -fno-rtti

# compiler options for C only
CFLAGS =

# linker options
LDFLAGS = -Os -Wl,--gc-sections -mcpu=cortex-m4 -mthumb -Tmk20dx256.ld
#LDFLAGS += -L $(CMSIS_LIB_PATH) -l$(CMSIS_LIB_NAME)

# additional libraries to link
LIBS = -lm


# names for the compiler programs
CC = $(abspath $(COMPILERPATH))/arm-none-eabi-gcc
CXX = $(abspath $(COMPILERPATH))/arm-none-eabi-g++
OBJCOPY = $(abspath $(COMPILERPATH))/arm-none-eabi-objcopy
OBJDUMP = $(abspath $(COMPILERPATH))/arm-none-eabi-objdump
SIZE = $(abspath $(COMPILERPATH))/arm-none-eabi-size

# automatically create lists of the sources and objects
# TODO: this does not handle Arduino libraries yet...
C_FILES := $(wildcard *.c)
CPP_FILES := $(wildcard *.cpp)
#OBJS := $(C_FILES:.c=.o) $(CPP_FILES:.cpp=.o)
OBJS := $(patsubst %.c,build/%.o,$(C_FILES)) $(CPP_FILES:.cpp=.o)

# the actual makefile rules (all .o files built by GNU make's default implicit rules)

all: $(TARGET).hex

$(TARGET).elf: $(OBJS) mk20dx128.ld
	$(CC) $(LDFLAGS) -o $@ $(OBJS) $(CMSIS_LIB_PATH)/lib$(CMSIS_LIB_NAME).a

$(OBJS): | objdir

objdir:
	@mkdir -p build

build/%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

build/%.o: %.cpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@


%.hex: %.elf
	$(SIZE) $<
	$(OBJDUMP) -d $< > $(TARGET).x
	$(OBJCOPY) -O ihex -R .eeprom $< $@
	#$(abspath $(TOOLSPATH))/teensy_post_compile -file=$(basename $@) -path=$(shell pwd) -tools=$(abspath $(TOOLSPATH))
	#-$(abspath $(TOOLSPATH))/teensy_reboot


# compiler generated dependency info
-include $(OBJS:.o=.d)

clean:
	rm -f build/*.o build/*.d $(TARGET).elf $(TARGET).hex $(TARGET).x


