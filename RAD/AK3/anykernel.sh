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
device.name1=dreamlte
device.name2=dream2lte
device.name3=greatlte
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
set_perm_recursive 0 0 750 750 $ramdisk/init*;
set_perm_recursive 0 0 755 755 $ramdisk/RAD;
set_perm 0 0 750 $ramdisk/*.rc;

## AnyKernel install
system_path=/system
# SAR check
if [ -e /system_root ]; then
	ui_print "System-as-root detected!...";
	mount -o remount,rw /system_root;
	system_path=/system_root/system;
	rm -f /system_root/system/vendor/etc/init/init.services.rc;
	insert_line /system_root/init.rc "init.services.rc" after "import /init.environ.rc" "import /init.services.rc\n";
	mv -f $ramdisk/init.services.rc /system_root;
	mv -f $ramdisk/fstab.samsungexynos8895 /system_root/fstab.samsungexynos8895;
	rm -rf /system_root/RAD;
	mv -f $ramdisk/RAD /system_root/RAD;
else
	mount -o remount,rw /system;
fi;

# Unpack boot image
dump_boot;

# Cleanup
ui_print "Cleaning old RZ leftovers...";
rm -f $ramdisk/rz/scripts/40perf;
rm -f $ramdisk/rz/scripts/90userinit;
rm -f $system_path/bin/sysinit_cm;
rm -f $system_path/etc/init.d/30zram;
rm -f $system_path/etc/init.d/40perf;
rm -f $system_path/etc/init.d/90userinit;
rm -f $ramdisk/RAD/scripts/40perf;
rm -f $ramdisk/RAD/scripts/90userinit;
rm -f $system_path/bin/sysinit_cm;
rm -f $system_path/etc/init.d/30zram;
rm -f $system_path/etc/init.d/40perf;
rm -f $system_path/etc/init.d/90userinit;

if [ ! -e /system_root ]; then
	insert_line $ramdisk/init.rc "init.services.rc" after "import /init.environ.rc" "import /init.services.rc\n";
	remove_line $ramdisk/fstab.samsungexynos8895 /dev/block/platform/11120000.ufs/by-name/CPEFS;
fi;

# Check device dtb
device_name=$(file_getprop /default.prop ro.product.device);
mv -f $home/*${device_name}*/Image $home/Image;
mv -f $home/*${device_name}*/dtb_$device_name.img $split_img/extra;

write_boot;
## end install

