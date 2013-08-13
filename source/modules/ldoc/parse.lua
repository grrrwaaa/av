-- parsing code for doc comments

local List = require 'pl.List'
local Map = require 'pl.Map'
local stringio = require 'pl.stringio'
local lexer = require 'ldoc.lexer'
local tools = require 'ldoc.tools'
local doc = require 'ldoc.doc'
local Item,File = doc.Item,doc.File

------ Parsing the Source --------------
-- This uses the lexer from PL, but it should be possible to use Peter Odding's
-- excellent Lpeg based lexer instead.

local parse = {}

local tnext, append = lexer.skipws, table.insert

-- a pattern particular to LuaDoc tag lines: the line must begin with @TAG,
-- followed by the value, which may extend over several lines.
local luadoc_tag = '^%s*@(%a+)'
local luadoc_tag_value = luadoc_tag..'(.*)'
local luadoc_tag_mod_and_value = luadoc_tag..'%[(.*)%](.*)'

-- assumes that the doc comment consists of distinct tag lines
local function parse_at_tags(text)
   local lines = stringio.lines(text)
   local preamble, line = tools.grab_while_not(lines,luadoc_tag)
   local tag_items = {}
   local follows
   while line do
      local tag, mod_string, rest = line :match(luadoc_tag_mod_and_value)
      if not tag then tag, rest = line :match (luadoc_tag_value) end
      local modifiers
      if mod_string then
         modifiers  = { }
         for x in mod_string :gmatch "[^,]+" do
            local k, v = x :match "^([^=]+)=(.*)$"
            if not k then k, v = x, x end
            modifiers[k] = v
         end
      end
      -- follows: end of current tag
      -- line: beginning of next tag (for next iteration)
      follows, line = tools.grab_while_not(lines,luadoc_tag)
      append(tag_items,{tag, rest .. '\n' .. follows, modifiers})
   end
   return preamble,tag_items
end

--local colon_tag = '%s*(%a+):%s'
local colon_tag = '%s*(%S-):%s'
local colon_tag_value = colon_tag..'(.*)'

local function parse_colon_tags (text)
   local lines = stringio.lines(text)
   local preamble, line = tools.grab_while_not(lines,colon_tag)
   local tag_items, follows = {}
   while line do
      local tag, rest = line:match(colon_tag_value)
      follows, line = tools.grab_while_not(lines,colon_tag)
      local value = rest .. '\n' .. follows
      if tag:match '^[%?!]' then
         tag = tag:gsub('^!','')
         value = tag .. ' ' .. value
         tag = 'tparam'
      end
      append(tag_items,{tag, value})
   end
   return preamble,tag_items
end

local Tags = {}
Tags.__index = Tags

function Tags.new (t)
   t._order = List()
   return setmetatable(t,Tags)
end

function Tags:add (tag,value)
   self[tag] = value
   --print('adding',tag,value)
   self._order:append(tag)
end

function Tags:iter ()
   return self._order:iter()
end

-- This takes the collected comment block, and uses the docstyle to
-- extract tags and values.  Assume that the summary ends in a period or a question
-- mark, and everything else in the preamble is the description.
-- If a tag appears more than once, then its value becomes a list of strings.
-- Alias substitution and @TYPE NAME shortcutting is handled by Item.check_tag
local function extract_tags (s,args)
   local preamble,tag_items
   if s:match '^%s*$' then return {} end
   if args.colon then --and s:match ':%s' and not s:match '@%a' then
      preamble,tag_items = parse_colon_tags(s)
   else
      preamble,tag_items = parse_at_tags(s)
   end
   local strip = tools.strip
   local summary, description = preamble:match('^(.-[%.?])(%s.+)')
   if not summary then
      -- perhaps the first sentence did not have a . or ? terminating it.
      -- Then try split at linefeed
      summary, description = preamble:match('^(.-\n\n)(.+)')
      if not summary then
         summary = preamble
      end
   end  --  and strip(description) ?
   local tags = Tags.new{summary=summary and strip(summary) or '',description=description or ''}
   for _,item in ipairs(tag_items) do
      local tag, value, modifiers = Item.check_tag(tags,unpack(item))
      -- treat multiline values more gently..
      if not value:match '\n[^\n]+\n' then
         value = strip(value)
      end

      if modifiers then value = { value, modifiers=modifiers } end
      local old_value = tags[tag]

      if not old_value then -- first element
         tags:add(tag,value)
      elseif type(old_value)=='table' and old_value.append then -- append to existing list
         old_value :append (value)
      else -- upgrade string->list
         tags:add(tag,List{old_value, value})
      end
   end
   return tags --Map(tags)
end

local _xpcall = xpcall
if true then
   _xpcall = function(f) return true, f() end
end



-- parses a Lua or C file, looking for ldoc comments. These are like LuaDoc comments;
-- they start with multiple '-'. (Block commments are allowed)
-- If they don't define a name tag, then by default
-- it is assumed that a function definition follows. If it is the first comment
-- encountered, then ldoc looks for a call to module() to find the name of the
-- module if there isn't an explicit module name specified.

local function parse_file(fname, lang, package, args)
   local line,f = 1
   local F = File(fname)
   local module_found, first_comment = false,true
   local current_item, module_item

   F.args = args

   F.base = package

   local tok,f = lang.lexer(fname)
   if not tok then return nil end

    local function lineno ()
      return tok:lineno()
    end

   local function filename () return fname end

   function F:warning (msg,kind,line)
      kind = kind or 'warning'
      line = line or lineno()
      io.stderr:write(fname..':'..line..': '..msg,'\n')
   end

   function F:error (msg)
      self:warning(msg,'error')
      io.stderr:write('LDoc error\n')
      os.exit(1)
   end

   local function add_module(tags,module_found,old_style)
      tags:add('name',module_found)
      tags:add('class','module')
      local item = F:new_item(tags,lineno())
      item.old_style = old_style
      module_item = item
   end

   local mod
   local t,v = tnext(tok)
   -- with some coding styles first comment is standard boilerplate; option to ignore this.
   if args.boilerplate and t == 'comment' then
      t,v = tnext(tok)
   end
   if t == '#' then -- skip Lua shebang line, if present
      while t and t ~= 'comment' do t,v = tnext(tok) end
      if t == nil then
         F:warning('empty file')
         return nil
      end
   end
   if lang.parse_module_call and t ~= 'comment'then
      while t and not (t == 'iden' and v == 'module') do
         t,v = tnext(tok)
      end
      if not t then
         if not args.ignore then
            F:warning("no module() call found; no initial doc comment")
         end
         --return nil
      else
         mod,t,v = lang:parse_module_call(tok,t,v)
         if mod ~= '...' then
            add_module({summary='(no description)'},mod,true)
            first_comment = false
            module_found = true
         end
      end
   end
   local ok, err = xpcall(function()
   while t do
      if t == 'comment' then
         local comment = {}
         local ldoc_comment,block = lang:start_comment(v)

         if ldoc_comment and block then
            t,v = lang:grab_block_comment(v,tok)
         end

         if lang:empty_comment(v)  then -- ignore rest of empty start comments
            t,v = tok()
         end

         while t and t == 'comment' do
            v = lang:trim_comment(v)
            append(comment,v)
            t,v = tok()
            if t == 'space' and not v:match '\n' then
               t,v = tok()
            end
         end

         if t == 'space' then t,v = tnext(tok) end

         local item_follows, tags, is_local, case
         if ldoc_comment then
            comment = table.concat(comment)

            if first_comment then
               first_comment = false
            else
               item_follows, is_local, case = lang:item_follows(t,v,tok)
            end
            if item_follows or comment:find '@' or comment:find ': ' then
               tags = extract_tags(comment,args)
               if doc.project_level(tags.class) then
                  module_found = tags.name
               end
               doc.expand_annotation_item(tags,current_item)
               -- if the item has an explicit name or defined meaning
               -- then don't continue to do any code analysis!
               if tags.name then
                  if not tags.class then
                     F:warning("no type specified, assuming function: '"..tags.name.."'")
                     tags:add('class','function')
                  end
                  item_follows, is_local = false, false
                elseif lang:is_module_modifier (tags) then
                  if not item_follows then
                     F:warning("@usage or @export followed by unknown code")
                     break
                  end
                  item_follows(tags,tok)
                  local res, value, tagname = lang:parse_module_modifier(tags,tok,F)
                  if not res then F:warning(value); break
                  else
                     if tagname then
                        module_item:set_tag(tagname,value)
                     end
                     -- don't continue to make an item!
                     ldoc_comment = false
                  end
               end
            end
         end
         -- some hackery necessary to find the module() call
         if not module_found and ldoc_comment then
            local old_style
            module_found,t,v = lang:find_module(tok,t,v)
            -- right, we can add the module object ...
            old_style = module_found ~= nil
            if not module_found or module_found == '...' then
               -- we have to guess the module name
               module_found = tools.this_module_name(package,fname)
            end
            if not tags then tags = extract_tags(comment,args) end
            add_module(tags,module_found,old_style)
            tags = nil
            if not t then
               F:warning(fname,' contains no items\n','warning',1)
               break;
            end -- run out of file!
            -- if we did bump into a doc comment, then we can continue parsing it
         end

         -- end of a block of document comments
         if ldoc_comment and tags then
            local line = t ~= nil and lineno()
            if t ~= nil then
               if item_follows then -- parse the item definition
                  local err = item_follows(tags,tok)
                  if err then F:error(err) end
               else
                  lang:parse_extra(tags,tok,case)
               end
            end
            if is_local or tags['local'] then
               tags['local'] = true
            end
            if tags.name then
               current_item = F:new_item(tags,line)
               current_item.inferred = item_follows ~= nil
               if doc.project_level(tags.class) then
                  if module_item then
                     F:error("Module already declared!")
                  end
                  module_item = current_item
               end
            end
            if not t then break end
         end
      end
      if t ~= 'comment' then t,v = tok() end
   end
   end,debug.traceback)
   if not ok then return F, err end
   if f then f:close() end
   return F
end

function parse.file(name,lang, args)
   local F,err = parse_file(name,lang,args.package,args)
   if err or not F then return F,err end
   local ok,err = xpcall(function() F:finish() end,debug.traceback)
   if not ok then return F,err end
   return F
end

return parse
