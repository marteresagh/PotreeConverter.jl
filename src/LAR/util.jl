function intersection(la,lb,p0,p1,p2)
	println("intersection")
    lab = lb-la
    p01 = p1 - p0
    p02 = p2 - p0

    n = Common.cross(p01,p02)
    det = Common.dot(-lab,n)
    if det != 0.
        t = (Common.dot(n,la-p0))/det
        u = Common.dot(Common.cross(p02,-lab),la-p0)/det
        v = Common.dot(Common.cross(-lab,p01),la-p0)/det
        return la+lab*t
    else
        println("segmento e piano paralleli: infite soluzioni o nessuna soluzione")
        return nothing
    end
end


function testplane(plane) # plane
	V = [
	    0.000000 0.000000 0.000000 0.000000 1.000000 1.000000 1.000000 1.000000
	    0.000000 0.000000 1.000000 1.000000 0.000000 0.000000 1.000000 1.000000
	    0.000000 1.000000 0.000000 1.000000 0.000000 1.000000 0.000000 1.000000
	]

	EV = [
	    [1, 2],
	    [3, 4],
	    [5, 6],
	    [7, 8],
	    [1, 3],
	    [2, 4],
	    [5, 7],
	    [6, 8],
	    [1, 5],
	    [2, 6],
	    [3, 7],
	    [4, 8],
	]

	FV = [
	    [1, 2, 3, 4],
	    [5, 6, 7, 8],
	    [1, 2, 5, 6],
	    [3, 4, 7, 8],
	    [1, 3, 5, 7],
	    [2, 4, 6, 8],
	]
	println("testplane")
	p0,p1,p2 = [plane[:,k] for k=1:3]
	ps = []
	for (h,k) in EV
		la = V[:,h]
		lb = V[:,k]
		sa = sign(Common.dot(Common.cross(p1-p0,p2-p0),la-p0))
		sb = sign(Common.dot(Common.cross(p1-p0,p2-p0),lb-p0))
		if !(sa == sb)
			p = intersection(la,lb,p0,p1,p2)
			if (p[1] >= 0. && p[1] <= 1) &&
				(p[2] >= 0. && p[2] <= 1) &&
				(p[3] >= 0. && p[3] <= 1)
				push!(ps, p)
			end
		end
	end
	points = convert(Matrix,hcat(ps...)')
	return points
end

function verts2edgesface(points) # points by row
	println("verts2edgesface")
	# traslation
	center = sum(points,dims=1)/size(points,1)
	points= points .- center
	# compute the linear map from random plane (a,b,c,d) to z=0
	p0,p1,p2 = [points[k,:] for k=1:3]
	M = Common.inv([p1+rand(3) p2 Common.cross(p1-p0,p2-p0)])
	# map vertex points
	face = M * (convert(Matrix,points'))
	# radial ordering of mapped points
	rays = [(face[:,k] .- center) for k=1:size(face,2)]
	ordering = []
	for k=1:size(face,2)
		y,x = rays[k][2],rays[k][1]
		alpha = atan(y,x)
		if abs(0.0-y) < 10^(-7)
			if abs(1.0-y) < 10^(-7)
				alpha= pi/2
			else abs(-1.0-y) < 10^(-7)
				alpha= -pi/2
			end
		end
		push!( ordering, (alpha,k) )
	end
	order = sort(ordering)
	# compute the edges (back-mapping of vertices not needed)
	lines = []
	for k=1:length(order)-1
		push!(lines, [order[k][2],order[k+1][2]])
	end
	push!(lines, [order[end][2],order[1][2]])
	face = sort(union(lines...))
	return lines, face
end


function planes(box,plane,aabb)
	println("planes")

	min = [aabb.x_min,aabb.y_min,aabb.z_min]
	max = [aabb.x_max,aabb.y_max,aabb.z_max]
	size = max-min

	M = Common.t(min...)*Common.s(size...)
	plane_transf = Common.apply_matrix(Common.inv(M),plane)

	points = testplane(plane_transf)
	verts = convert(Common.Points, points')
	# get output
	lines,face = verts2edgesface(points)
	edges = convert(Common.Cells, lines)
	# struct assembly of convex faces
	str = Common.Struct([ (Common.apply_matrix(M,verts), [face], edges) ])
	push!( box, str )
end


# GL.VIEW(GL.GLExplode(V,FVs,1.1,1.1,1.1,99,1));
# GL.VIEW(GL.GLExplode(V,EVs,1.5,1.5,1.5,99,1));
# GL.VIEW(GL.GLExplode(V,CVs,1,1,1,99,0.2));
