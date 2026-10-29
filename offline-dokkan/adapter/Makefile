CC ?= cc
CFLAGS ?= -O2 -std=c11 -Wall -Wextra -Werror
SQLITE_CFLAGS ?= -I../../downloads/sqlite-amalgamation/source
SQLITE_LIBS ?= -Wl,-l:libsqlite3.so.0
JAVA_HOME ?= ../../downloads/unit-creator-tools/jdk/usr/lib/jvm/java-21-openjdk-amd64
JAVAC ?= ../../unit-creator/tools/javac
BUILD = build
CORE = $(filter-out ../core/od_cli.c ../core/test_%.c ../core/check_%.c,$(wildcard ../core/*.c))
.PHONY: all java check clean
all: $(BUILD)/libodbridge.so
$(BUILD):
	mkdir -p $@
$(BUILD)/libodbridge.so: od_bridge.c od_bridge.h $(CORE) $(wildcard ../core/*.h) android/od_jni.c | $(BUILD)
	$(CC) $(CFLAGS) $(SQLITE_CFLAGS) -I$(JAVA_HOME)/include -I$(JAVA_HOME)/include/linux -fPIC -shared od_bridge.c $(CORE) android/od_jni.c $(SQLITE_LIBS) -pthread -o $@
java: all
	$(JAVAC) --release 8 -Xlint:-options -d $(BUILD)/classes android/com/personal/offlinedokkan/OfflineCore.java
check: java
	python3 check_bridge.py
clean:
	rm -rf $(BUILD)
