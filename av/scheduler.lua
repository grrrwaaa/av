local coro, coresume, coyield, corunning, costatus = coroutine.create, coroutine.resume, coroutine.yield, coroutine.running, coroutine.status
local max, min, abs = math.max, math.min, math.abs
local traceback = debug.traceback
local format = string.format

local eventqs = {}	

-- weak map of coroutine to the scheduler/list that contains it:
local Cmap = {}
-- set the map keys to be weak, so that they don't prevent garbage collections:
setmetatable(Cmap, { __mode = "k" })

local 
function eventq_find(e) 
	local q = rawget(eventqs, e)
	if not q then
		q = {}
		rawset(eventqs, e, q)
	end
	return q
end

local 
function dump(q)
	local m = q.next
	local i = 1
	while m and i < 10 do
		print(i, m.C, m.t, m.C == wincoro)
		m = m.next
		i = i + 1
	end
end

local 
function sched(q, m)

	--print("before sched", m.C, m.t, m.C == wincoro, "at", q.t) dump(q)

	local t = m.t
	-- insertion sort to derive prev & next:
	local p, n = q, q.next
	while n and n.t <= t do
		p = n
		n = n.next
	end
	
	-- note: n might be nil (if insertion at tail of list)
	m.next = n
	-- p is either the q itself, or a scheduled task within q
	-- if p == q then we are inserting at the head
	-- i.e. n == q.next
	-- note: n might be nil; either way works
	-- if p ~= q then there is no change to q.next	
	--assert(p, "queue is corrupt")
	p.next = m
	-- print("after sched") dump(q)
end

local 
function remove(q, C)
	if q.t then
		-- it is a scheduler
		local p = q.next
		if p then
			if p.C == C then
				-- remove from head:
				q.next = p.next
				return
			else
				while p do
					local n = p.next
					if n and n.C == C then
						-- remove n:
						p.next = n.next
						return
					end
					p = n
				end
			end
		end
	else
		-- it is an event list
		for i = 1, #q do
			if q[i] == C then
				table.remove(q, i)
				return
			end
		end
	end
end

local 
function panic()
	for C, q in pairs(Cmap) do
		remove(q, C)
	end
end


local 
function resume(C, ...)
	local status = costatus(C)
	if status == "suspended" then
		local ok, err = coresume(C, ...)
		if not ok then print(traceback(C, err)) end
	end
end

local task = {}
task.__index = task

function task:__tostring()
	return format("task(%q)", self.C)
end

function task:cancel()
	-- is it temporal or event based?
end

--[[#Scheduler - Objects
The scheduler handles coroutines. Note that most methods of the schedule are global, hence you can call go() and sequence() 
without needing to do so as a method call. If you do need to refer to the scheduler explicitly it is globally stored in the 'scheduler' variable.  
  
See http://lua-av.mat.ucsb.edu/blog/?p=137 for details.  

## Example Usage ##
`a = Agent('green')  
b = sequence( function() a:color(Random(), Random(), Random() end, .5))`
--]]


return {
--[[###Scheduler.panic : method
**description** stop all coroutines from running. This method is globalized (is that a word?)
--]]
	panic = panic,
	
	create = function()
		local self = { t=0, next=nil }
		
--[[###Scheduler.cancel : method
**description** stop a passed coroutine from running  
**param** *coroutine* Coroutine. The coroutine to cancel
--]]
		self.cancel = function(C)
			remove(Cmap[C], C)
		end

--[[###Scheduler.now : method
**description** return the time the scheduler has been active
--]]		
		self.now = function()
			return self.t
		end

--[[###Scheduler.wait : method
**description** pause execution of a coroutine created using go() or sequence()  
**param** *timeToWait* Seconds OR String. The amount of time to pause the coroutine for. If a string is passed, wait for an event of the provided name
--]]		
		self.wait = function(e)
			local C = corunning()
			if type(e) == "number" then
				sched(self, { C=C, t=self.t+abs(e) } )
				-- store in map:
				Cmap[C] = self
			elseif type(e) == "string" then
				local q = eventq_find(e)
				q[#q+1] = C
				-- store in map:
				Cmap[C] = q
			end
			return coyield()
		end
		
--[[###Scheduler.event : method
**description** trigger an event(s). This will cause all coroutines waiting for the named event to continue running.
**param** *eventNames* List. The events to trigger
--]]    
		self.event = function(e, ...)
			local q = eventq_find(e)
			--for each coro in the list, schedule it (and remove it from the list)
			--check number waiting at this point, 
			--since within resume() a coro may re-await on the same event
			local size = #q
			for i = 1,size do
				local C = q[1]
				-- remove from queue:
				table.remove(q, 1)
				-- remove from map:
				Cmap[C] = nil
				-- call it:
				resume(C, ...)
			end
		end	
    
--[[###Scheduler.go : method
**description** Creates a coroutine to be executed that can be paused using wait()  
  
**Example Usage**  
`a = Agent()  
go(function()  
  while true do  
    a:color(random(), random(), random())  
    wait(1)  
  end  
end)`  
  
**param** *delay* OPTIONAL. Seconds. An optional amount of time to wait before beginning the coroutine  
**param** *function* Function. A function be executed by the coroutine  
**param** *arg list* OPTIONAL. Any extra arguments will be passed to the function call by the coroutine  
--]]			
		self.go = function(e, func, ...)
			local args
			if type(e) == "function" then
				args = {func, ...}
				func = e
				e = 0
			else
				args = {...}
			end
			
			local C
			if type(e) == "string" then
				local C = coro(func)
				local q = eventq_find(e)
				q[#q+1] = C
				-- store in map
				Cmap[C] = q
				return C
			elseif type(e) == "number" then
				-- ouch; a closure for each go() isn't ideal...
				local C = coro(function() return func(unpack(args)) end)
				sched(self, { C=C, t=self.t+e } )
				-- store in map:
				Cmap[C] = self
				return C
			else
				error("bad type for go")
			end
		end
		
		self.due = function()
			local m = self.next
			return m and m.t or nil
		end	
		
		self.update = function(t, maxtimercallbacks)
			-- check for pending coros:
			
			-- show current stack:
			--print("||||||||||||||||| update", t) dump(self)
			
			local calls = 0
			local m = self.next
			while m and m.t < t do
				self.t = max(self.t, m.t)
				-- remove from queue:
				self.next = m.next
				-- remove from map:
				Cmap[m.C] = nil
				-- resume it:
				resume(m.C)
				-- continue:
				calls = calls + 1
				if maxtimercallbacks and calls > maxtimercallbacks then
					-- probably a runaway loop?
					print("warning: maxtimercallbacks exceeded")
					return
				end
				-- continue to next item (which may have changed during resume)
				m = self.next
			end
			--print("no more to run", m)
			self.t = t
		end
		self.advance = function(dt)
			self.update(self.t + dt)
		end
		
--[[#Sequence - Objects
**description** Creates a coroutine that can be start and stopped and calls its function repeatedly or a specified number of times.  
  
**Example Usage**  
`a = Agent();  
b = sequence( function() a:color(Random(), Random(), Random()) end, .25, 10)`  
  
**param** *function* Function. The function to be repeatedly executed  
**param** *time* Seconds. The amount of time to wait before each execution of the funtion  
**param** *repeats* OPTIONAL. Number. If provided, the sequencer will only run the specified number of times and then stop itself.  
--]]       
		self.sequence = function(func, _time, repeats)
			local _stop = false
			local _scheduler = self
			local count = 0
			local limited = (type(repeats) == 'number')
			
			local o
			o = {
				run = function()
					while not _stop do
						func()
						wait(_time)
						if limited and count < repeats then
							count = count + 1
							if count >= repeats then 
								_stop = true
               					count = 0
							end
						end
					end
				end,
--[[###Sequence.start : method
**description** Start a sequence that has been previously stopped
--]]
--[[###Sequence.stop : method
**description** Stop a running sequence
--]]
				stop = function()
					_stop = true
				end,
				start = function()
					_stop = false
					_scheduler.go(o.run)
				end,
--[[###Sequence.time : method
**description** Change the amount of time between function executions by the sequencer  
**param** *time* Number. The number of seconds to wait in between function calls
--]]
				time = function(s,t)
				  _time = t
				end,
			}
			
			self.go(o.run)

			return o
		end
		
		return self
	end,
}