#
# OpenJazz for the RetroFW
#
# by pingflood; 2019
#

TARGET = snowman/snowman.dge

CHAINPREFIX 	:= /opt/mipsel-RetroFW-linux-uclibc
CROSS_COMPILE 	:= $(CHAINPREFIX)/usr/bin/mipsel-linux-

CC 		:= $(CROSS_COMPILE)gcc
STRIP 	:= $(CROSS_COMPILE)strip
CXX 	:= $(CROSS_COMPILE)g++
RANLIB	:= $(CROSS_COMPILE)ranlib
AR		:= $(CROSS_COMPILE)ar

SYSROOT		:= $(shell $(CC) --print-sysroot)
SDL_LIBS    := $(shell $(SYSROOT)/usr/bin/sdl-config --libs)
SDL_CFLAGS  := $(shell $(SYSROOT)/usr/bin/sdl-config --cflags)

export SYSROOT CC STRIP CXX RANLIB AR

#==stuff linked to
DYNAMIC = -lSDL_ttf -lSDL_mixer -lSDL_image -lSDL_net -lSDL -lm
#==global Flags. Even on the gp2x with 16 kb Cache, -O3 is much better then -Os
CFLAGS = -O3 -fsingle-precision-constant -fPIC
# Testtweaks: -fgcse-lm -fgcse-sm -fsched-spec-load -fmodulo-sched -funsafe-loop-optimizations -Wunsafe-loop-optimizations -fgcse-las -fgcse-after-reload -fvariable-expansion-in-unroller -ftracer -fbranch-target-load-optimize
GENERAL_TWEAKS = -ffast-math
#==PC==
# FLAGS = -g -DDINGUX $(GENERAL_TWEAKS)
FLAGS = -DGCW -DDINGUX $(GENERAL_TWEAKS) -DFAST_MULTIPLICATION #-DFAST_DIVISION

SPARROW_FOLDER = ./src/sparrow3d

SPARROW3D_LIB = libsparrow3d.so
SPARROWNET_LIB = libsparrowNet.so
SPARROWSOUND_LIB = libsparrowSound.so

# TARGET = "Default (change with make TARGET=otherTarget. See All targets with make targets)"

BUILD = snowman/
SPARROW_LIB = $(SPARROW_FOLDER)

LIB += -L$(SPARROW_LIB)
INCLUDE += -I$(SPARROW_FOLDER)
# DYNAMIC += -lsparrow3d -lsparrowSound -lsparrowNet
STATIC += ./src/sparrow3d/libsparrow3d.a ./src/sparrow3d/libsparrowSound.a ./src/sparrow3d/libsparrowNet.a

CFLAGS += $(PARAMETER) $(FLAGS)

export CHAINPREFIX CROSS_COMPILE FLAGS

all: snowman
	@echo "=== Built for Target "$(TARGET)" ==="

targets:
	@echo "The targets are the same like for sparrow3d. :P"

snowman: src/ballbullet.h src/bullet_new.h src/drawlevel.h src/particle.h src/bullet.h src/drawcharacter.h src/enemy.h src/level.h src/splashscreen.h src/snow.h src/snowman.c makeBuildDir
	make -C $(SPARROW_FOLDER) static
	# cp -u $(SPARROW_LIB)/$(SPARROW3D_LIB) $(BUILD)
	# cp -u $(SPARROW_LIB)/$(SPARROWNET_LIB) $(BUILD)
	# cp -u $(SPARROW_LIB)/$(SPARROWSOUND_LIB) $(BUILD)
	$(CC) $(CFLAGS) $(LINK_FLAGS) src/snowman.c $(SDL_CFLAGS) $(INCLUDE) $(LIB) $(SDL_LIB) $(STATIC) $(DYNAMIC) -o $(TARGET)

makeBuildDir:
	 @if [ ! -d $(BUILD:/snowman=/) ]; then mkdir $(BUILD:/snowman=/);fi
	 @if [ ! -d $(BUILD) ]; then mkdir $(BUILD);fi

clean:
	make -C $(SPARROW_FOLDER) clean
	rm -f *.o
	rm -f $(TARGET)

ipk: all
	@rm -rf /tmp/.snowman-ipk/ && mkdir -p /tmp/.snowman-ipk/root/home/retrofw/games/snowman /tmp/.snowman-ipk/root/home/retrofw/apps/gmenu2x/sections/games
	@cp -r \
	snowman/snowman.dge \
	snowman/snowman.png \
	snowman/controls.cfg \
	snowman/snowman.man.txt \
	snowman/data \
	snowman/levels \
	snowman/sounds \
	/tmp/.snowman-ipk/root/home/retrofw/games/snowman
	@cp snowman/snowman.lnk /tmp/.snowman-ipk/root/home/retrofw/apps/gmenu2x/sections/games
	@sed "s/^Version:.*/Version: $$(date +%Y%m%d)/" snowman/control > /tmp/.snowman-ipk/control
	@cp snowman/conffiles /tmp/.snowman-ipk/
	@tar --owner=0 --group=0 -czvf /tmp/.snowman-ipk/control.tar.gz -C /tmp/.snowman-ipk/ control conffiles
	@tar --owner=0 --group=0 -czvf /tmp/.snowman-ipk/data.tar.gz -C /tmp/.snowman-ipk/root/ .
	@echo 2.0 > /tmp/.snowman-ipk/debian-binary
	@ar r snowman/snowman.ipk /tmp/.snowman-ipk/control.tar.gz /tmp/.snowman-ipk/data.tar.gz /tmp/.snowman-ipk/debian-binary

opk: all
	mksquashfs \
	snowman/default.retrofw.desktop \
	snowman/snowman.dge \
	snowman/snowman.png \
	snowman/controls.cfg \
	snowman/snowman.man.txt \
	snowman/data \
	snowman/levels \
	snowman/sounds \
	snowman/snowman.opk \
	-all-root -noappend -no-exports -no-xattrs
