CC ?= cc
CFLAGS ?= -O2 -std=c11 -Wall -Wextra -Werror
SQLITE_CFLAGS ?= -I../../downloads/sqlite-header
ifeq ($(shell uname -s),Darwin)
SQLITE_LIBS ?= -lsqlite3 -framework Security
else
SQLITE_LIBS ?= -Wl,-l:libsqlite3.so.0
endif
BUILD = build
.PHONY: all check check-summons check-creator check-experience check-schedules check-upgrades check-stats-store check-stats check-kai check-potential-store check-training-store clean
all: $(BUILD)/od-cli $(BUILD)/libodcore.so
$(BUILD):
	mkdir -p $@
$(BUILD)/od-cli: od_core.c od_core.h summons.c summons.h progression.c progression.h schedules.c schedules.h schedules_store.c schedules_store.h card_stats.c card_stats.h potential.c potential.h training.c training.h kai_training.c kai_training.h json_values.c json_values.h od_cli.c | $(BUILD)
	$(CC) $(CFLAGS) $(SQLITE_CFLAGS) od_core.c summons.c progression.c schedules.c schedules_store.c card_stats.c potential.c training.c kai_training.c json_values.c od_cli.c $(SQLITE_LIBS) -o $@
$(BUILD)/libodcore.so: od_core.c od_core.h summons.c summons.h progression.c progression.h schedules.c schedules.h schedules_store.c schedules_store.h card_stats.c card_stats.h potential.c potential.h training.c training.h kai_training.c kai_training.h json_values.c json_values.h | $(BUILD)
	$(CC) $(CFLAGS) $(SQLITE_CFLAGS) -fPIC -shared od_core.c summons.c progression.c schedules.c schedules_store.c card_stats.c potential.c training.c kai_training.c json_values.c $(SQLITE_LIBS) -o $@
check: $(BUILD)/libodcore.so
	python3 check_core.py
check-summons: $(BUILD)/libodcore.so
	python3 check_summon_store.py
check-creator: $(BUILD)/libodcore.so
	python3 check_creator_store.py
check-experience: $(BUILD)/libodcore.so
	python3 check_experience_store.py
check-schedules: $(BUILD)/libodcore.so
	python3 check_schedule_store.py
check-upgrades: $(BUILD)/libodcore.so
	python3 check_upgrade_store.py
check-stats-store: $(BUILD)/libodcore.so
	python3 check_stats_store.py
$(BUILD)/libcardstats-check.so: card_stats.c card_stats.h | $(BUILD)
	$(CC) $(CFLAGS) $(SQLITE_CFLAGS) -fPIC -shared card_stats.c $(SQLITE_LIBS) -o $@
check-stats: $(BUILD)/libcardstats-check.so
	python3 check_card_stats.py
check-kai: $(BUILD)/libodcore.so
	python3 check_kai_store.py
check-potential-store: $(BUILD)/libodcore.so
	python3 check_potential_store.py
check-training-store: $(BUILD)/libodcore.so
	python3 check_training_store.py
clean:
	rm -rf $(BUILD)
