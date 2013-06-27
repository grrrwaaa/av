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
function sched(q, m)
	if not q.head then
		q.head = m
	elseif m.t < q.head.t then
		m.next = q.head
		q.head = m
	else
		-- insertion sort, nothing fancy
		local p = q.head
		local n = p.next
		while n and n.t <= m.t do
			p = n
			n = n.next
		end
		m.next = n
		p.next = m
	end
end

local 
function remove(q, C)
	if q then
		if q.t then
			-- it is a scheduler
			local p = q.head
			if p then
				if p.C == C then
					-- remove from head:
					q.head = p.next
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
		local self = { t=0 }
		
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
				local C = coro(function() return func(unpack(args)) end)
				sched(self, { C=C, t=self.t+e } )
				-- store in map:
				Cmap[C] = self
				return C
			else
				error("bad type for go")
			end
		end
		
		self.update = function(t)
			-- check for pending coros:
			local m = self.head
			while m and m.t < t do
				self.t = max(self.t, m.t)
				-- remove from queue:
				local n = m.next
				self.head = n
				-- remove from map:
				Cmap[m.C] = nil
				-- resume it:
				resume(m.C)
				-- continue to next item:
				m = n
			end
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