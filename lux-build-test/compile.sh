#!/usr/bin/env zsh

LUA="luajit" # "lua", "lua-5.1", "luajit", etc
LUX_LUA="jit" # "5.4", "5.1", "jit", etc
export LUASTATIC="luastatic"

echo Invoked in $(pwd)

cd "$(realpath $(dirname $0))"

echo Running in $(pwd)

lx build || exit 1

LUASTATIC="luastatic_patched"
cp .lux/$LUX_LUA/bin/unwrapped/luastatic .lux/$LUX_LUA/bin/unwrapped/luastatic_patched 
cp .lux/$LUX_LUA/bin/luastatic .lux/$LUX_LUA/bin/luastatic_patched 

# Point Lux to our new patched script
sed -i "s/bin\/unwrapped\/luastatic/bin\/unwrapped\/luastatic_patched/g" .lux/$LUX_LUA/bin/luastatic_patched 
# Patch the script to move all references to `....lux.jit.src.main` to `main`
sed -i "s/out(('	lua_setfield(L, -2, \"%s\");\n\n\'):format(file.dotpath_noextension))/\
local location = file.dotpath_noextension \
if location:find(\".src.\", 1, true) then \
local loc = location:sub(location:find(\".src.\", location:find(\"@\", 1, true), true)+5) \
	print(\"Matched: \"..loc) \
	location = loc \
end \
out(('	lua_setfield(L, -2, \"%s\");\n\n'):format(location))/g" \
  .lux/$LUX_LUA/bin/unwrapped/luastatic_patched

cd src

SHARED_LIBS=$(find ../.lux/$LUX_LUA/*/lib -name "*.so" | tr '\n' ' ')
echo "Shared libraries: $SHARED_LIBS"

lx exec $LUASTATIC -- \
  main.lua \
  *.lua \
  $(pwd)/../.lux/$LUX_LUA/*/src/*.lua \
  $(pwd)/../.lux/$LUX_LUA/*/src/**/*.lua \
  $SHARED_LIBS \
  $(pkg-config --libs $LUA)

cd ..
if [[ -z "$1" ]]; then
    OUT_FILE=$(grep "^name = " lux.toml | cut -d'"' -f2)
else
    OUT_FILE="$1"
fi
mv src/main $OUT_FILE
rm src/main.luastatic.c