dist/anapay.lua: main.lua mm.lua helpers.lua anapay.lua
	mkdir -p dist
	./lua_modules/bin/amalg.lua -o dist/anapay.lua -s main.lua mm helpers anapay

.PHONY: deps
deps: 
	luarocks install dkjson
	luarocks install http
	luarocks install amalg