# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=// RAD Kernel // #StayRAD // 
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=dream2lte
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
'; } # end properties

# shell variables
block=/dev/block/platform/11120000.ufs/by-name/BOOT;
is_slot_device=0;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;

system_path=/system
# SAR check
if [ -e /system_root ]; then
	ui_print "System-as-root detected!...";
	mount -o remount,rw /system_root;
	system_path=/system_root/system;
else
	mount -o remount,rw /system;
fi;

# Cleanup
ui_print "Cleaning old RZ leftovers...";
rm -f $ramdisk/rz/scripts/40perf;
rm -f $ramdisk/rz/scripts/90userinit;
rm -f $system_path/bin/sysinit_cm;
rm -f $system_path/etc/init.d/40perf;
rm -f $system_path/etc/init.d/90userinit;

ui_print "Initializing init.d support...";
mkdir $system_path/etc/init.d;
chmod 755 $system_path/etc/init.d;

## AnyKernel install
dump_boot;

# begin ramdisk changes

# end ramdisk changes

write_boot;

ui_print "Done! - RAD-ified ur device!";

## end install

