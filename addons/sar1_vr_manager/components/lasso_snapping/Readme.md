# Overview

Overview: This is a simple library for calculating what I'm going to call the voronoi power of a point in 3d space relative to another point and direction. The practical use is to provide a metric that tells us how likely it is that a user with bad aim meant to to aim for an arbitrary point in 3d space with a vr controller. This could have been a single function, but I'm making it a library to make room for a stretch goal where we allow directional focus changes - Players will be able to change what object we assume their aiming at by using directional keys or joystick input. It will function like tab and arrow keys do on 2d UIs.

## Calculations

NOTE: The points are in 3d space, but we are calculating 2d voronoi and delaunay diagrams on the surface of a sphere. Things might get fucky wucky. This mostly just applies to changing snap targets when using the joystick.
	- You can think of the space as the surface of a sphere that's centered around the player's controller and the controller points towards (0,0) or the origin of the space.
	- Any vector or line in the space can be thought of as a vector or line on the surface of the sphere in 3d space that's tangent to the sphere.
	- When we move a point 5 units on the surface of this sphere along a vector V1, we draw a second vector from the controller (the center of th sphere) to the point and call it V2. Then we take the cross product of V2 and V1 and call it V3. We rotate the point around the center of the sphere using V3 as an axis by 5 units (probably degrees) and where we end up is the resulting point.
	- When we say we are moving a point on the surface of the sphere along the joystick's movement vector, we measure the joystick's direction by assuming forward is up from the player's viewpoint. This vector is a 3d vector. To convert it to a 2d vector in our space we take the normal of the surface of the sphere at the point and find the rejection of the joystick movement vector with respect to that normal. A vector rejection is the opposite of a vector projection.

Power is defined by ((snap bias) / euclidian distance) / angular distance. We calculate the power for all n points and return the index of the point that had the highest. Takes O(n) time. For an added bonus we move all points towards the controller pointer laser before doing this calculation to simulate a spherical collider.

When we snap to a new target, we travel along the edge of a delaunay triange, but we only need to calculate one piece of the delaunay triangle. If done right this should take O(n) time as well.
	- We have a point A that we are snapped to and the joystick moves towards some unknown point B. Our goal is to figure out which point is B.
	- We pick an arbitrary point P1 and draw a vector between it and point A. We calculate the angle between this vector and the direction the joystick moved. If this is more than 90 degrees, we quit early.
	- If the angle is less than 90 we calculate the draw a vector starting at point A and parallel to the joystick's movement, and calculate the distance at which that new vector intersects the bisecting line of the vector from point A to point P1.
		- The bisecting line of the vector from A to P1 is just the line that's perpendicular to the vector from A to P1 and intersects it at it's midpoint.
	- For points P2 through Pn we repeat the process and only keep track of the point with the shortest distance.
	- The point with the shortest distance is B so we return it.
		- When we draw a vector from A to Pn, we are drawing a possible edge of a delaunay triangle. We don't know if it is part of a delaunay triange because we didn't check, but we know that by checking all possible edges from A, we are checking all possible delaunay triangles' edges that start from A
		- The bisecting line of a delaunay edge is a line in a voronoi diagram because of the relationship between voronoi diagrams and delaunay edges. so by looking at the intersection of our joystick's vector and the bisecting lines, we're essentially asking if I moved from point A in the direction that I moved the joystick, which voronoi cell would I end up in.
		- Not every bisecting line is part of the voronoi diagram because not every vector from A was an edge of a delaunay triangle, but because of the way voronoi diagrams work, the nearest bisecting line must be part of the voronoi diagram and it must be the border between point A's cell and the next nearest cell.
		- We want B to be the next nearest snapping point in the direction we moved our joystick. The point that generated the next nearest cell we just found must be B.

## Future extensions

Add support for not spherical colliders. We should be able to snap to line and box shaped objects without costing too much performance.
	- Basically instead of a fixed point, we calculate the point nearest the laser coming out of the controller. This calculation happens in 3d space and for simple shapes like boxes and lines we can just solve a simple system of equations. After that, everything else is the same. Line colliders are basically the same capsules except instead of a width and radius we have the snapping power.
