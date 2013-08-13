local format = string.format

local input = "/usr/local/include/GL/glfw.h"
local name = "glfw"
local defpre = "GLFW_"

print(string.format("typedef struct %s_functions_t {", name))
local h = io.popen(string.format("gcc -E -P %s", input))
for l in h:lines() do
	for ret, fname, args in l:gmatch("(%w+)%s"..name.."(%w+)(%b());") do
		print(string.format("\t%s (*%s)%s;", ret, fname, args))
	end	
end
h:close()
local h = io.open(input):read("*a")
for k, v in h:gmatch("#define%s+"..defpre.."([%w_]+)%s+([%w_%+%(%)]+)") do
	print(format("\t int %s;", k))
end
print(string.format("} %s_functions_t;", name))
print(string.format("extern \"C\" %s_functions_t * av_load_%s();", name, name))
print()





print(string.format("%s_functions_t %s;", name, name))
print(string.format("%s_functions_t * av_load_%s() {", name, name))
local h = io.popen(string.format("gcc -E -P %s", input))
for l in h:lines() do
	for fname in l:gmatch("%w+%s"..name.."(%w+)%b();") do
		print(string.format("\t%s.%s = %s%s;", name, fname, name, fname))
	end	
end
h:close()
local h = io.open(input):read("*a")
for k, v in h:gmatch("#define%s+"..defpre.."([%w_]+)%s+([%w_%+%(%)]+)") do
	print(format("\t%s.%s = %s%s;", name, k, defpre, k))
end
print(string.format("\treturn &%s;", name, name))
print("}")

