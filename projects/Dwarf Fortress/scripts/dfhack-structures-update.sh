#!/bin/bash -x

cd "$1"
shift
Version="$1"
shift

export RUBYLIB="$RUBYLIB:`pwd`/metasm"

cd df-structures

git remote add BenLubar git@github.com:BenLubar/df-structures.git
git push -f BenLubar master

git branch -D auto-symbols-update || true
git checkout -b auto-symbols-update

# find global variables
ruby ../df_misc/dump_df_globals.rb "../win32/Dwarf Fortress.exe" > win32_globals.xml.tmp
ruby ../df_misc/dump_df_globals.rb "../win64/Dwarf Fortress.exe" > win64_globals.xml.tmp
ruby ../df_misc/dump_df_globals.rb "../linux32/libs/Dwarf_Fortress" > linux32_globals.xml.tmp
ruby ../df_misc/dump_df_globals.rb "../linux64/libs/Dwarf_Fortress" > linux64_globals.xml.tmp
ruby ../df_misc/dump_df_globals.rb "../osx32/dwarfort.exe" > osx32_globals.xml.tmp
ruby ../df_misc/dump_df_globals.rb "../osx64/dwarfort.exe" > osx64_globals.xml.tmp

# find vtables
ruby ../df_misc/scan_vtable.rb "../win32/Dwarf Fortress.exe" > win32_vtable.xml.tmp
ruby ../df_misc/scan_vtable.rb "../win64/Dwarf Fortress.exe" > win64_vtable.xml.tmp
ruby ../df_misc/scan_vtable.rb "../linux32/libs/Dwarf_Fortress" > linux32_vtable.xml.tmp
ruby ../df_misc/scan_vtable.rb "../linux64/libs/Dwarf_Fortress" > linux64_vtable.xml.tmp
ruby ../df_misc/scan_vtable.rb "../osx32/dwarfort.exe" > osx32_vtable.xml.tmp
ruby ../df_misc/scan_vtable.rb "../osx64/dwarfort.exe" > osx64_vtable.xml.tmp

## find constructors
#ruby ../df_misc/scan_ctors.rb "../win32/Dwarf Fortress.exe" > win32_ctors.xml.tmp || true
#ruby ../df_misc/scan_ctors.rb "../win64/Dwarf Fortress.exe" > win64_ctors.xml.tmp || true
#ruby ../df_misc/scan_ctors.rb "../linux32/libs/Dwarf_Fortress" > linux32_ctors.xml.tmp || true
#ruby ../df_misc/scan_ctors.rb "../linux64/libs/Dwarf_Fortress" > linux64_ctors.xml.tmp || true
#ruby ../df_misc/scan_ctors_osx.rb "../osx32/dwarfort.exe" > osx32_ctors.xml.tmp || true
#ruby ../df_misc/scan_ctors_osx.rb "../osx64/dwarfort.exe" > osx64_ctors.xml.tmp || true

## find keydisplay
#ruby ../df_misc/scan_keydisplay.rb "../win32/Dwarf Fortress.exe" > win32_keydisplay.xml.tmp
#ruby ../df_misc/scan_keydisplay.rb "../win64/Dwarf Fortress.exe" > win64_keydisplay.xml.tmp
#ruby ../df_misc/scan_keydisplay.rb "../osx32/dwarfort.exe" > osx32_keydisplay.xml.tmp
#ruby ../df_misc/scan_keydisplay.rb "../osx64/dwarfort.exe" > osx64_keydisplay.xml.tmp

# generate codegen.out.xml
perl ./codegen.pl

# size of df::unit structure is required for scan_startdwarfcount
sizeunit_win32="`perl ../df_misc/get_sizeofunit.pl codegen/codegen.out.xml windows 32`"
sizeunit_win64="`perl ../df_misc/get_sizeofunit.pl codegen/codegen.out.xml windows 64`"
sizeunit_linux32="`perl ../df_misc/get_sizeofunit.pl codegen/codegen.out.xml linux 32`"
sizeunit_linux64="`perl ../df_misc/get_sizeofunit.pl codegen/codegen.out.xml linux 64`"

# find start dwarf count
ruby ../df_misc/scan_startdwarfcount.rb "../win32/Dwarf Fortress.exe" "$sizeunit_win32" > win32_startdwarfcount.xml.tmp
ruby ../df_misc/scan_startdwarfcount.rb "../win64/Dwarf Fortress.exe" "$sizeunit_win64" > win64_startdwarfcount.xml.tmp
ruby ../df_misc/scan_startdwarfcount.rb "../linux32/libs/Dwarf_Fortress" "$sizeunit_linux32" > linux32_startdwarfcount.xml.tmp
ruby ../df_misc/scan_startdwarfcount.rb "../linux64/libs/Dwarf_Fortress" "$sizeunit_linux64" > linux64_startdwarfcount.xml.tmp
ruby ../df_misc/scan_startdwarfcount.rb "../osx32/dwarfort.exe" "$sizeunit_linux32" > osx32_startdwarfcount.xml.tmp
ruby ../df_misc/scan_startdwarfcount.rb "../osx64/dwarfort.exe" "$sizeunit_linux64" > osx64_startdwarfcount.xml.tmp

# find addresses that text will be text wants
ruby ../df_misc/scan_twbt.rb "../win32/Dwarf Fortress.exe" "$(grep viewscreen_dwarfmodest win32_vtable.xml.tmp | grep -o '0x[0-9a-f]\+')" > win32_twbt.xml.tmp
ruby ../df_misc/scan_twbt.rb "../win64/Dwarf Fortress.exe" "$(grep viewscreen_dwarfmodest win64_vtable.xml.tmp | grep -o '0x[0-9a-f]\+')" > win64_twbt.xml.tmp
ruby ../df_misc/scan_twbt.rb "../linux32/libs/Dwarf_Fortress" "$(grep viewscreen_dwarfmodest linux32_vtable.xml.tmp | grep -o '0x[0-9a-f]\+')" > linux32_twbt.xml.tmp
ruby ../df_misc/scan_twbt.rb "../linux64/libs/Dwarf_Fortress" "$(grep viewscreen_dwarfmodest linux64_vtable.xml.tmp | grep -o '0x[0-9a-f]\+')" > linux64_twbt.xml.tmp
ruby ../df_misc/scan_twbt.rb "../osx32/dwarfort.exe" "$(grep viewscreen_dwarfmodest osx32_vtable.xml.tmp | grep -o '0x[0-9a-f]\+')" > osx32_twbt.xml.tmp
ruby ../df_misc/scan_twbt.rb "../osx64/dwarfort.exe" "$(grep viewscreen_dwarfmodest osx64_vtable.xml.tmp | grep -o '0x[0-9a-f]\+')" > osx64_twbt.xml.tmp

rm -rf codegen

for file in globals startdwarfcount vtable twbt do
	sed -e 's/^/        /' -i {win,linux,osx}{32,64}_"$file".xml.tmp
done

Win32Timestamp="0x`winedump-stable "../win32/Dwarf Fortress.exe" | grep TimeDateStamp | grep -o '[0-9A-F]\{8\}'`"
Win64Timestamp="0x`winedump-stable "../win64/Dwarf Fortress.exe" | grep TimeDateStamp | grep -o '[0-9A-F]\{8\}'`"
Linux32MD5="`md5sum -b "../linux32/libs/Dwarf_Fortress" | cut -d ' ' -f 1`"
Linux64MD5="`md5sum -b "../linux64/libs/Dwarf_Fortress" | cut -d ' ' -f 1`"
OSX32MD5="`md5sum -b "../osx32/dwarfort.exe" | cut -d ' ' -f 1`"
OSX64MD5="`md5sum -b "../osx64/dwarfort.exe" | cut -d ' ' -f 1`"

write_syms() {
	symname=$1
	ostype=$2
	identifier=$3
	symprefix=$4

	echo "    <symbol-table name='v$Version $symprefix$symname' os-type='$ostype'>" >> symbols.xml.tmp
	echo "        $identifier" >> symbols.xml.tmp
	echo >> symbols.xml.tmp
	cat ${symname}_startdwarfcount.xml.tmp >> symbols.xml.tmp
	cat ${symname}_twbt.xml.tmp >> symbols.xml.tmp
	echo >> symbols.xml.tmp
	cat ${symname}_globals.xml.tmp >> symbols.xml.tmp
	echo >> symbols.xml.tmp
	cat ${symname}_vtable.xml.tmp >> symbols.xml.tmp
	echo >> symbols.xml.tmp
	echo "    </symbol-table>" >> symbols.xml.tmp
}

sed '/<!-- end windows -->/Q' symbols.xml > symbols.xml.tmp
echo >> symbols.xml.tmp
write_syms win32 windows "<binary-timestamp value='$Win32Timestamp'/>" "SDL "
echo >> symbols.xml.tmp
write_syms win64 windows "<binary-timestamp value='$Win64Timestamp'/>" "SDL "
echo >> symbols.xml.tmp
sed -n '/<!-- end windows -->/,/<!-- end linux -->/ p' symbols.xml | sed '$d' >> symbols.xml.tmp
echo >> symbols.xml.tmp
write_syms linux32 linux "<md5-hash value='$Linux32MD5'/>"
echo >> symbols.xml.tmp
write_syms linux64 linux "<md5-hash value='$Linux64MD5'/>"
echo >> symbols.xml.tmp
sed -n '/<!-- end linux -->/,/<!-- end osx -->/ p' symbols.xml | sed '$d' >> symbols.xml.tmp
echo >> symbols.xml.tmp
write_syms osx32 darwin "<md5-hash value='$OSX32MD5'/>"
echo >> symbols.xml.tmp
write_syms osx64 darwin "<md5-hash value='$OSX64MD5'/>"
echo >> symbols.xml.tmp
sed -n '/<!-- end osx -->/,$ p' symbols.xml >> symbols.xml.tmp

mv -f symbols.xml.tmp symbols.xml
rm -f *.xml.tmp

perl ./make-keybindings.pl < ../linux64/g_src/keybindings.h > df.keybindings.xml

git add symbols.xml df.keybindings.xml
git commit -m "Automatically generated symbols.xml for DF $Version"

git push -fu BenLubar auto-symbols-update
