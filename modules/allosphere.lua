--- allosphere: Utilities relating specifically to the AlloSphere

local gl = require "gl"
local vec3 = require "vec3"
local displaylist = require "displaylist"

local sin, cos = math.sin, math.cos
local pi = math.pi
local sqrt = math.sqrt

local allosphere_list


local allosphere = {
	drawframe = drawframe,
	
	capsuleRadius = 4.842, --meters (approximate. not yet measured by hand)
	cylinderHeight = 2.09, --meters (82" measured by David with tape measure)
	doorwayY = 0.94, -- meters (height of doorway above y=0)
	capRadius = 0.595, -- meters (radius of sphere end-caps)
}

allosphere.cylinderHalf = allosphere.cylinderHeight/2
allosphere.sphereCenterFront = vec3(0, 0, -allosphere.cylinderHalf)
allosphere.sphereCenterBack = vec3(0, 0, allosphere.cylinderHalf)
allosphere.sphereCenterTop = vec3(0, -allosphere.capsuleRadius, 0)
allosphere.sphereCenterBottom = vec3(0, allosphere.capsuleRadius, 0)

function allosphere:forwardIntersectionRaySphere(rayDirection, sphereCenter)
    --[[
     ray:       r = o + (d * t) = d * t
     circle:    (r - c).(r - c) = radius^2
     combined:  (d*t - c).(d*t - c) = radius^2
     (d.d)t^2 + (-2*c.d)t + (c.c - radius^2) = 0
     
     Let:
     A = d.d
     B = -2 * c.d
     C = c.c - radius^2
     
     t = (-B +/- sqrt(B*B-4AC)) / (2A), since t > 0
     
     Let B' = c.d = -B/2
     t = (B' +/- sqrt(B'*B'-AC)) / A
     
     This is cheaper to compute than  t = (-B + sqrt(B*B-4AC)) / (2A)
    --]]
    local A = rayDirection:dot(rayDirection)
    local B = rayDirection:dot(sphereCenter)
    local C = sphereCenter:dot(sphereCenter) - self.capsuleRadius*self.capsuleRadius    
    local t = (B + sqrt(B*B-A*C))/A
    --this t will be positive, and will give us the "forward" (t>0) intersection.
    --(since the ray origin is the center of the capsule which lies inside
    --the front and back sphere, we will always have a positive and negative
    --value) 
    return rayDirection * t
end

function allosphere:capsuleFitting(unfittedPoint) 
    --SUMMARY
    --[[
     Q: Does point project on back hemisphere, cylindrical section, or front 
     hemisphere?
    
     Shoot a ray from the center of the capsule, through the unfitted 
     point. Find where this ray intersects the infinite cylinder that is 
     concentric with and of same radius as the capsule, and whose axis 
     is the long axis of the capsule, which is also the z-axis.
    
     The cylindrical section of the capsule intersects the hemispherical sections.
     These intersections, which are circles, lie in the planes z = h/2 and
     z = -h/2, where h is the height (length) of the cylindrical section.
    
     To find where our ray-infinite cylinder intersection point lies in
     relation to these two dividing plains, and thus which of the three
     sections the projected (fitted) point we wish to compute lies on,
     we simply look at the z value and compare it to -h/2 and h/2.
    
     following OpenGL convention:
     
     back hemisphere: z > h/2
     front hemisphere: z < -h/2
     cylindrical section: -h/2 < z < h/2
    
     (To save time we can simply compute this z value of the infinite
     cylinder intersection and neglect the y and z components.
     That is what is done here.)
    
     Q: Now that we know on which of the three sections of the capsule the
     fitted point will lie on, where is it exactly?
    
     If the point is determined to lie on a hemisphere, we take our
     original ray (with its origin at the center of the capsule, (0,0,0),
     and passing through the unfitted point) and compute its intersection
     with a sphere centered at either (0,0,h/2) or (0,0,-h/2).
    
     If the point lies on the cylindrical section, we compute its
     intersection with the infinite cylinder.
    
     We fit our data to an ideal capsule by essentially moving
     the raw points away from or towards the center so that they may rest
     on the ideal capsule's surface.  It is assumed that our data has already
     been shifted and rotated so that the unfitted data points are aligned with 
     the fitting capsule, though they will not share the same scale before fitting.
     
     END SUMMARY
     --]]
    
    --Origin of ray is the center of the capsule.  Take unfitted point and
    --divide by length to get the ray direction vector:
    local direction = unfittedPoint:normalizenew()
        
    --[[
     Find the ray's intersection with the infinite cylinder of which the 
     cylindrical section is part.
     Cylindrical cross-section is in x-y plane.
     
     cylinder equation: r.x^2 + r.y^2 = radius^2
     ray equation: r = o + d*t = d*t, since o = (0,0,0)
     combined: (d.x*t)^2 + (d.y*t)^2 = radius^2
     solve for t: t = radius/sqrt(d.x^2+d.y^2)
     point of intersection: r = d*t = d * radius/sqrt(d.x^2 + d.y^2)
     we just need the z-coordinate for our test:
     r.z = d.z * radius / sqrt(d.x^2 + d.y^2):
    --]]
	
	if direction.x==0. and direction.y==0. then
        --if x=y=0, then the point lies at the apex of a hemisphere and not on the infinite cylinder
        return direction * (self.capsuleRadius + self.cylinderHalf)
    end
    
	local lengthxy = self.capsuleRadius / sqrt(direction.x * direction.x + direction.y * direction.y)
	local rz = direction.z * lengthxy
        
    if (rz > self.cylinderHalf) then
        --project onto rear hemisphere
        --since +z is towards the back of the capsule
        return self:forwardIntersectionRaySphere(direction, vec3(0, 0, self.cylinderHalf))
    
    elseif(rz < -self.cylinderHalf) then
        --project onto front hemisphere
        return self:forwardIntersectionRaySphere(direction, vec3(0, 0, -self.cylinderHalf))
	else
        --project onto cylinder.
        --instead of just computing the z-component as we did above,
        --compute the entire point now that we know we need it.
        --derived above: r = d * radius/sqrt(d.x^2 + d.y^2)        
        return direction * lengthxy
    end
end

local allosphere_list = displaylist(function()
	local self = allosphere
	local numpanels = 24
		
	-- starting angle:
	local pstart = math.pi/2 - math.atan(self.doorwayY / self.capsuleRadius)
	gl.Begin(gl.LINES)
	for ie = 0, numpanels do
		local e = pstart * (2.*(ie/numpanels - 0.5))
		
		local vertex = vec3(math.sin(e), math.cos(e), 0)
		gl.Vertex(self.sphereCenterFront + vertex * self.capsuleRadius)
		gl.Vertex(self.sphereCenterBack + vertex * self.capsuleRadius)
	end
	gl.End()
	
	-- each rib:
	local numslices = 15
	local numlats = 12
	for ia = 0, numslices do
		local a = math.pi * (ia/numslices - 0.5)
		gl.Begin(gl.LINE_STRIP)
		for ie = 0, numlats do
			local e = math.pi * (ie/numlats - 0.5)
			local vertex = vec3(
				cos(e) * sin(a),
				sin(e),
				cos(e) * cos(a)
			)
			gl.Vertex(self.sphereCenterFront - vertex * self.capsuleRadius)
		end
		gl.End()
	end
	for ie = 0, numlats do
		local e = pi * (ie/(numlats) - 0.5);
		gl.Begin(gl.LINE_STRIP);
		for ia = 0, numslices do
			local a = pi * (ia/(numslices) - 0.5);
			local vertex= vec3(
				cos(e) * sin(a),
				sin(e),
				cos(e) * cos(a)
			);
			gl.Vertex(self.sphereCenterFront - vertex * self.capsuleRadius);
		end
		gl.End();
	end
	
	for ia = 0, numslices do
		local a = math.pi * (ia/numslices - 0.5)
		gl.Begin(gl.LINE_STRIP)
		for ie = 0, numlats do
			local e = math.pi * (ie/numlats - 0.5)
			local vertex = vec3(
				cos(e) * sin(a),
				sin(e),
				cos(e) * cos(a)
			)
			gl.Vertex(self.sphereCenterBack + vertex * self.capsuleRadius)
		end
		gl.End()
	end
	for ie = 0, numlats do
		local e = pi * (ie/(numlats) - 0.5);
		gl.Begin(gl.LINE_STRIP);
		for ia = 0, numslices do
			local a = pi * (ia/(numslices) - 0.5);
			local vertex= vec3(
				cos(e) * sin(a),
				sin(e),
				cos(e) * cos(a)
			);
			gl.Vertex(self.sphereCenterBack + vertex * self.capsuleRadius);
		end
		gl.End();
	end
	
	-- the caps:
	local e = math.acos(self.capRadius/self.capsuleRadius)
	
	gl.Begin(gl.LINE_STRIP);
	for ia = 0, numslices do
		local a = pi * (ia/(numslices) - 0.5);
		local vertex = vec3(
			cos(e) * sin(a),
			sin(e),
			cos(e) * cos(a)
		);
		gl.Vertex(self.sphereCenterFront - vertex * self.capsuleRadius);
	end
	gl.End();
	gl.Begin(gl.LINE_STRIP);
	for ia = 0, numslices do
		local a = pi * (ia/(numslices) - 0.5);
		local vertex = vec3(
			cos(e) * sin(a),
			sin(e),
			cos(e) * cos(a)
		);
		gl.Vertex(self.sphereCenterBack + vertex * self.capsuleRadius);
	end
	gl.End();
	gl.Begin(gl.LINE_STRIP);
	for ia = 0, numslices do
		local a = pi * (ia/(numslices) - 0.5);
		local vertex = vec3(
			cos(-e) * sin(a),
			sin(-e),
			cos(-e) * cos(a)
		);
		gl.Vertex(self.sphereCenterFront - vertex * self.capsuleRadius);
	end
	gl.End();
	gl.Begin(gl.LINE_STRIP);
	for ia = 0, numslices do
		local a = pi * (ia/(numslices) - 0.5);
		local vertex = vec3(
			cos(-e) * sin(a),
			sin(-e),
			cos(-e) * cos(a)
		);
		gl.Vertex(self.sphereCenterBack + vertex * self.capsuleRadius);
	end
	gl.End()
end)

function allosphere:drawframe()
	allosphere_list()
end

return allosphere