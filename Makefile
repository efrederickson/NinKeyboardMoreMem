ARCHS = armv7 armv7s arm64
#TARGET = iphone:8.1
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NinKeyboardMoreMem
NinKeyboardMoreMem_FILES = Tweak.xm
NinKeyboardMoreMem_LIBRARIES = jetslammed

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 NinKeyboard SpringBoard"
