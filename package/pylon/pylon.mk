################################################################################
# pylon
################################################################################

PYLON_VERSION = 26.10
PYLON_SOURCE = pylon_linux-aarch64_26101.tar.gz
PYLON_SITE = $(HOME)/projects/downloads
PYLON_SITE_METHOD = file
PYLON_STRIP_COMPONENTS = 0
PYLON_LICENSE = Proprietary
PYLON_REDISTRIBUTE = NO
PYLON_INSTALL_STAGING = YES

define PYLON_INSTALL_STAGING_CMDS
	cp -dpfr $(@D)/include/* $(STAGING_DIR)/usr/include/
	cp -dpfr $(@D)/lib/* $(STAGING_DIR)/usr/lib/
endef

define PYLON_INSTALL_TARGET_CMDS
	cp -dpfr $(@D)/lib/* $(TARGET_DIR)/usr/lib/
endef

$(eval $(generic-package))
