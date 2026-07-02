##################################################################
# Board PID # Board Name       # PRODUCT # Note
##################################################################
# EC220_G5 V2  # TP-LINK EC220_G5 V2    # MT7620  #
##################################################################

CFLAGS += -DBOARD_EC220_G5_V2 -DVENDOR_TPLINK
BOARD_NUM_USB_PORTS=0

### TP-LINK firmware description ###
TPLINK_HWID=0x04DA857C
TPLINK_HWREV=0x0C000600
TPLINK_HWREVADD=0x04000000
TPLINK_FLASHLAYOUT=8Mmtk
TPLINK_HVERSION=3
