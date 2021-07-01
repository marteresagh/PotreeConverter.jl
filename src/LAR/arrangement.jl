function interior_to_f(triangle,f,V,FV,EV,FE)
	v1,v2,v3 = triangle
	u = V[:,v2]-V[:,v1]
	v = V[:,v3]-V[:,v1]
	w = Common.cross(u,v)
	T = [1. 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1]; T[1:3,4] = -V[:,v1]
	R = [1. 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1]; R[1:3,1:3] = [u v w]; R = R'
	mapping = R * T

	trianglepoints = [[V[:,v1] V[:,v2] V[:,v3]]; ones(3)']
	pts = mapping * trianglepoints
	points2D = [pts[r,:] for r = 1:size(pts,1)
				if !(all(pts[r,:].==0) || all(pts[r,:].==1) )]
	p2D = hcat(points2D...)'
	checkpoint = 0.4995 .* p2D[:,1] + 0.4995 .* p2D[:,2] + 0.001 .* p2D[:,3]

	cellpoints = [V[:,FV[f]]; ones(length(FV[f]))' ]
	points = mapping * cellpoints
	verts2D = [points[r,:] for r = 1:size(points,1)
				if !(all(points[r,:].==0) || all(points[r,:].==1) )]
	P2D = hcat(verts2D...)'

	vdict = Dict(collect(zip(FV[f], 1:length(FV[f]))))
	celledges = [[vdict[v] for v in EV[e]] for e in FE[f]]

	out = pointInPolygonClassification(P2D,celledges)(checkpoint)
	if out=="p_in"
		return true
	else
		return false
	end
end


function ordering(triangles,V)
	normals = []
	v1,v2,v3 = triangles[1]
	if v1>v2 v1,v2 = v2,v1 end
	e3 = Common.normalize(V[:,v2]-V[:,v1])
	e1 = Common.normalize(V[:,v3]-V[:,v1])
	e2 = Common.normalize(Common.cross(e1,e3))
	basis = [e1 e2 e3]
	transform = Common.inv(basis)

	angles = []
	for (v1,v2,v3) in triangles
		w1 = Common.normalize(V[:,v3]-V[:,v1])
		w2 = transform * w1
		w3 = Common.cross([0,0,1],w2)
		push!(normals,w3)
	end
	for k=1:length(normals)
		angle = Common.atan(normals[k][2],normals[k][1])
		push!(angles,angle)
	end
	#pairs = sort(collect(zip(angles,1:length(triangles))))
	pairs = sort([(angle,k) for (k,angle) in enumerate(angles)])
	order = [k for (angle,k) in pairs]
	return order
end


function ord(hinge::Int64, bd1::AbstractSparseVector{Int,Int}, V::Array{Float64,2},
FV::Array{Array{Int64,1},1}, EV::Array{Array{Int64,1},1}, FE::Array{Array{Int64,1},1})
	cells = SparseArrays.findnz(bd1)[1]
	triangles = []

	function area(v1,v2,v3)
		u = V[:,v2]-V[:,v1]
		v = V[:,v3]-V[:,v1]
		out = Common.norm(Common.cross(u,v)) # actually, to be divided by two
		return out
	end

	for f in cells
		v1,v2 = EV[hinge]
		index = findfirst(v -> (area(v1,v2,v)≠0), FV[f])
		v3 = FV[f][index]

		# test if [v1,v2,v3] interior to f
		while true
			if interior_to_f([v1, v2, v3],f,V,FV,EV,FE)
				push!(triangles, [v1,v2,v3])
				break
			else
				index = findnext(v -> (area(v1,v2,v)≠0), FV[f], index+1)
				v3 = FV[f][index]
			end
		end
	end
	order = ordering(triangles,V)
	return [cells[index] for index in order]
end

function mynext(cycle, pivot)
	len = length(cycle)
	ind = findall(x -> x==pivot, cycle)[1]
	nextIndex = ind==len ? 1 : ind+1
	return cycle[nextIndex][1]
end


function myprev(cycle, pivot)
	len = length(cycle)
	ind = findall(x->x==pivot, cycle)[1]
	nextIndex = ind==1 ? len : ind-1
	return cycle[nextIndex][1]
end

#using Plasm

function build_copFC(rV, rcopEV, rcopFE)
#function build_copFC(V,FV,EV,copFE)

	# G&F -> Pao data structures
	V = convert(Common.Points, rV')
	EV = cop2lar(rcopEV)
	fe = cop2lar(rcopFE)
	fv = [union([EV[e] for e in fe[f]]...) for f=1:length(fe)]
	FV = convert(Common.Cells, fv)
	copFE = rcopFE
	VV = [[v] for v=1:size(V,2)]
	model = (V, [VV,EV,FV])
	#Plasm.View(Plasm.numbering(.25)(model))

	copEF = copFE'
	FE = [SparseArrays.findnz(copFE[k,:])[1] for k=1:size(copFE,1)]
	# Initializations
	m,n = size(copEF)
	marks = zeros(Int8,n);
	I = Int64[]; J = Int64[]; W = Int8[];
	jcol = 0
	choose(marks) = findfirst(x -> x<2, marks)

	# Main loop (adding one copFC's column stepwise)
	while sum(marks) < 2n
		# select a (d−1)-cell, "seed" of the column extraction
		σ = choose(marks)
		if marks[σ] == 0
			cd1 = sparsevec([σ], Int8[1], n)
		elseif marks[σ] == 1
			cd1 = sparsevec([σ], Int8[-1], n)
		end
		# compute boundary cd2 of seed cell
		cd2 = copEF * cd1
		# loop until (boundary) cd2 becomes empty
		while nnz(cd2)≠0
			corolla = sparsevec([], Int8[], m)
			# for each “hinge” τ cell
			for τ ∈ (.*)(SparseArrays.findnz(cd2)...)
				#compute the  coboundary
				tau = sparsevec([abs(τ)], Int64[sign(τ)], m)  # ERROR: index out of bound here!
				bd1 = transpose(transpose(tau) * copEF)
				cells2D = SparseArrays.findnz(bd1)[1]
				# compute the  support
				inters = intersect(cells2D, SparseArrays.findnz(cd1)[1])
				if inters ≠ []
					pivot = inters[1]
				else
					error("no pivot")
				end
				# compute the new adj cell
				fan = ord(abs(τ),bd1,V,FV,EV,FE) # ord(pivot,bd1)
				if τ > 0
					adj = mynext(fan,pivot)
				elseif τ < 0
					adj = myprev(fan,pivot)
				end
				# orient adj
				if copEF[abs(τ),adj] ≠ copEF[abs(τ),pivot]
					corolla[adj] = cd1[pivot]
				else
					corolla[adj] = -(cd1[pivot])
				end
			end
			# insert corolla cells in current cd1
			for (k,val) in zip(SparseArrays.findnz(corolla)...)
				cd1[k] = val
			end
			# compute again the boundary of cd1
			cd2 = copEF * cd1
		end
		for σ ∈ SparseArrays.findnz(cd1)[1]
			# update the counters of used cells
			marks[σ] += 1
		end
		# append a new column to [∂d+]
		# copFC += cd1
		rows, vals = SparseArrays.findnz(cd1)
		jcol += 1
		append!(I,rows)
		append!(J,[ jcol for k=1:nnz(cd1) ])
		append!(W,vals)
	end
	copCF = sparse(J,I,W)
	return copCF
end



"""
    bbox(vertices::Points)

The axis aligned bounding box of the provided set of n-dim `vertices`.

The box is returned as the couple of `Points` of the two opposite corners of the box.
"""
function bbox(vertices::Common.Points)
    minimum = mapslices(x->min(x...), vertices, dims=1)
    maximum = mapslices(x->max(x...), vertices, dims=1)
    minimum, maximum
end

"""
    bbox_contains(container, contained)

Check if the axis aligned bounding box `container` contains `contained`.

Each input box must be passed as the couple of `Points` standing on the opposite corners of the box.
"""
function bbox_contains(container, contained)
    b1_min, b1_max = container
    b2_min, b2_max = contained
    all(map((i,j,k,l)->i<=j<=k<=l, b1_min, b2_min, b2_max, b1_max))
end

"""
    face_area(V::Points, EV::Cells, face::Cell)

The area of `face` given a geometry `V` and an edge topology `EV`.
"""
function face_area(V::Common.Points, EV::Common.Cells, face::Common.Cell)
    return face_area(V, build_copEV(EV), face)
end

function face_area(V::Common.Points, EV::Common.ChainOp, face::Common.Cell)
    function triangle_area(triangle_points::Common.Points)
        ret = ones(3,3)
        ret[:, 1:2] = triangle_points
        return .5*Common.det(ret)
    end

    area = 0

    fv = buildFV(EV, face)

    verts_num = length(fv)
    v1 = fv[1]

    for i in 2:(verts_num-1)

        v2 = fv[i]
        v3 = fv[i+1]

        area += triangle_area(V[[v1, v2, v3], :])
    end

    return area
end

"""
    skel_merge(V1::Points, EV1::ChainOp, V2::Points, EV2::ChainOp)

Merge two **1-skeletons**
"""
function skel_merge(V1::Common.Points, EV1::Common.ChainOp, V2::Common.Points, EV2::Common.ChainOp)
    V = [V1; V2]
    EV = blockdiag(EV1,EV2)
    return V, EV
end

"""
    skel_merge(V1::Points, EV1::ChainOp, FE1::ChainOp, V2::Points, EV2::ChainOp, FE2::ChainOp)

Merge two **2-skeletons**
"""
function skel_merge(V1::Common.Points, EV1::Common.ChainOp, FE1::Common.ChainOp,
					V2::Common.Points, EV2::Common.ChainOp, FE2::Common.ChainOp)
    FE = blockdiag(FE1,FE2)
    V, EV = skel_merge(V1, EV1, V2, EV2)
    return V, EV, FE
end

"""
    delete_edges(todel, V::Points, EV::ChainOp)

Delete edges and remove unused vertices from a **2-skeleton**.

Loop over the `todel` edge index list and remove the marked edges from `EV`.
The vertices in `V` which remained unconnected after the edge deletion are deleted too.
"""
function delete_edges(todel, V::Common.Points, EV::Common.ChainOp)
    tokeep = setdiff(collect(1:EV.m), todel)
    EV = EV[tokeep, :]

    vertinds = 1:EV.n
    todel = Array{Int64, 1}()
    for i in vertinds
        if length(EV[:, i].nzind) == 0
            push!(todel, i)
        end
    end

    tokeep = setdiff(vertinds, todel)
    EV = EV[:, tokeep]
    V = V[tokeep, :]

    return V, EV
end




"""
    buildFV(EV::Cells, face::Cell)

The list of vertex indices that expresses the given `face`.

The returned list is made of the vertex indices ordered following the traversal order to keep a coherent face orientation.
The edges are need to understand the topology of the face.

In this method the input face must be expressed as a `Cell`(=`SparseVector{Int8, Int}`) and the edges as `Cells`.
"""
function buildFV(EV::Common.Cells, face::Common.Cell)
    return buildFV(build_copEV(EV), face)
end

"""
    buildFV(copEV::ChainOp, face::Cell)

The list of vertex indices that expresses the given `face`.

The returned list is made of the vertex indices ordered following the traversal order to keep a coherent face orientation.
The edges are need to understand the topology of the face.

In this method the input face must be expressed as a `Cell`(=`SparseVector{Int8, Int}`) and the edges as `ChainOp`.
"""
function buildFV(copEV::Common.ChainOp, face::Common.Cell)
    startv = -1
    nextv = 0
    edge = 0

    vs = Array{Int64, 1}()

    while startv != nextv
        if startv < 0
            edge = face.nzind[1]
            startv = copEV[edge,:].nzind[face[edge] < 0 ? 2 : 1]
            push!(vs, startv)
        else
            edge = setdiff(intersect(face.nzind, copEV[:, nextv].nzind), edge)[1]
        end
        nextv = copEV[edge,:].nzind[face[edge] < 0 ? 1 : 2]
        push!(vs, nextv)

    end

    return vs[1:end-1]
end

"""
    buildFV(copEV::ChainOp, face::Array{Int, 1})

The list of vertex indices that expresses the given `face`.

The returned list is made of the vertex indices ordered following the traversal order to keep a coherent face orientation.
The edges are need to understand the topology of the face.

In this method the input face must be expressed as a list of vertex indices and the edges as `ChainOp`.
"""
function buildFV(copEV::Common.ChainOp, face::Array{Int, 1})
    startv = face[1]
    nextv = startv

    vs = []
    visited_edges = []

    while true
        curv = nextv
        push!(vs, curv)

        edge = 0

        for edgeEx in copEV[:, curv].nzind
            nextv = setdiff(copEV[edgeEx, :].nzind, curv)[1]
            if nextv in face && (nextv == startv || !(nextv in vs)) && !(edgeEx in visited_edges)
                edge = edgeEx
                break
            end
        end

        push!(visited_edges, edge)

        if nextv == startv
            break
        end
    end

    return vs
end


"""
    build_copFE(FV::Cells, EV::Cells)

The signed `ChainOp` from 1-cells (edges) to 2-cells (faces)
"""
function build_copFE(FV::Common.Cells, EV::Common.Cells)
	copFE = u_coboundary_1(FV, EV) # unsigned
	faceedges = [findnz(copFE[f,:])[1] for f=1:size(copFE,1)]

	f_edgepairs = Array{Array{Int64,1}}[]
	for f=1:size(copFE,1)
		edgepairs = Array{Int64,1}[]
		for v in FV[f]
			push!(edgepairs, [e for e in faceedges[f] if v in EV[e]])
		end
		push!(f_edgepairs, edgepairs)
	end
	for f=1:size(copFE,1)
		for (e1,e2) in f_edgepairs[f]
			v = intersect(EV[e1], EV[e2])[1]
			copFE[f,e1] = EV[e1][2]==v ? 1 : -1
			copFE[f,e2] = EV[e2][1]==v ? 1 : -1
		end
	end
	return copFE
end



"""
    build_copEV(EV::Cells, signed=true)

The signed (or not) `ChainOp` from 0-cells (vertices) to 1-cells (edges)
"""
function build_copEV(EV::Common.Cells, signed=true)
    setValue = [-1, 1]
    if signed == false
        setValue = [1, 1]
    end

    maxv = max(map(x->max(x...), EV)...)
    copEV = spzeros(Int8, length(EV), maxv)

    for (i,e) in enumerate(EV)
        e = sort(collect(e))
        copEV[i, e] = setValue
    end

    return copEV
end

"""
    build_cops(edges::Cells, faces::Cells)

The vertices-edges and edges-faces chain operators (`copEV::ChainOp`, `copFE::ChainOp`)
"""
function build_cops(edges::Common.Cells, faces::Common.Cells)
    copEV = build_copEV(edges)
    FV = Cells(map(x->buildFV(copEV,x), faces))
    copFE = build_copFE(FV, edges)

    return [copEV, copFE]
end

"""
    vin(vertex, vertices_set)

Checks if `vertex` is one of the vertices inside `vertices_set`
"""
function vin(vertex, vertices_set)
    for v in vertices_set
        if vequals(vertex, v)
            return true
        end
    end
    return false
end

"""
    vequals(v1, v2)

Check the equality between vertex `v1` and vertex `v2`
"""
function vequals(v1, v2)
    err = 10e-8
    return length(v1) == length(v2) && all(map((x1, x2)->-err < x1-x2 < err, v1, v2))
end


function vcycle( copEV::Common.ChainOp, copFE::Common.ChainOp, f::Int64 )
	edges,signs = SparseArrays.findnz(copFE[f,:])
	vpairs = [s>0 ? SparseArrays.findnz(copEV[e,:])[1] :
					reverse(SparseArrays.findnz(copEV[e,:])[1])
				for (e,s) in zip(edges,signs)]
	a = [pair for pair in vpairs if length(pair)==2]
	function mycat(a::Common.Cells)
		out=[]
		for cell in a append!(out,cell) end
		return out
	end
	vs = collect(Set(mycat(a)))
	vdict = Dict(zip(vs,1:length(vs)))
	edges = [[vdict[pair[1]], vdict[pair[2]]] for pair in vpairs if length(pair)==2]
	return vs, edges
end


"""
    triangulate(model::LARmodel)

Full constrained Delaunnay triangulation of the given 3-dimensional `LARmodel`
"""
function triangulate(model::Common.LARmodel)
    V, topology = model
    cc = build_cops(topology...)
    return triangulate(V, cc)
end

"""
    triangulate(V::Points, cc::ChainComplex)

Full constrained Delaunnay triangulation of the given 3-dimensional model (given with topology as a `ChainComplex`)
"""
function triangulate(V::Common.Points, cc::Common.ChainComplex)
	copEV, copFE = cc[1:2]

    triangulated_faces = Array{Any, 1}(undef, copFE.m)

    for f in 1:copFE.m
        if f % 10 == 0
            print(".")
        end

        edges_idxs = copFE[f, :].nzind
        edge_num = length(edges_idxs)
        edges = zeros(Int64, edge_num, 2)

        #fv = Lar.buildFV(copEV, copFE[f, :])
        fv, edges = vcycle(copEV, copFE, f)
		if fv ≠ []
			vs = V[fv, :]
	        v1 = Common.normalize(vs[2, :] - vs[1, :])
	        v2 = [0, 0, 0]
	        v3 = [0, 0, 0]
	        err = 1e-8
	        i = 3
	        while -err < Common.norm(v3) < err
	            v2 = Common.normalize(vs[i, :] - vs[1, :])
	            v3 = Common.cross(v1, v2)
	            i = i % size(vs,1) + 1
	        end
	        M = reshape([v1; v2; v3], 3, 3)
	        vs = (vs*M)[:, 1:2]
			v = convert(Common.Points, vs'[1:2,:])
			vmap = Dict(zip(fv,1:length(fv))) # vertex map
			mapv = Dict(zip(1:length(fv),fv)) # inverse vertex map

			trias = triangulate2d(v,edges)
			triangulated_faces[f] = [[mapv[v] for v in tria] for tria in trias]
		end
    end

    return triangulated_faces
end

"""
    point_in_face(point, V::Points, copEV::ChainOp)

Check if `point` is inside the area of the face bounded by the edges in `copEV`
"""
function point_in_face(point, V::Common.Points, copEV::Common.ChainOp)

    function pointInPolygonClassification(V,EV)

        function crossingTest(new, old, status, count)
        if status == 0
            status = new
            return status, (count + 0.5)
        else
            if status == old
                return 0, (count + 0.5)
            else
                return 0, (count - 0.5)
            end
        end
        end

        function setTile(box)
        tiles = [[9,1,5],[8,0,4],[10,2,6]]
        b1,b2,b3,b4 = box
        function tileCode(point)
            x,y = point
            code = 0
            if y>b1 code=code|1 end
            if y<b2 code=code|2 end
            if x>b3 code=code|4 end
            if x<b4 code=code|8 end
            return code
        end
        return tileCode
        end

        function pointInPolygonClassification0(pnt)
            x,y = pnt
            xmin,xmax,ymin,ymax = x,x,y,y
            tilecode = setTile([ymax,ymin,xmax,xmin])
            count,status = 0,0

            for k in 1:EV.m
                edge = EV[k,:]
                p1, p2 = V[edge.nzind[1], :], V[edge.nzind[2], :]
                (x1,y1),(x2,y2) = p1,p2
                c1,c2 = tilecode(p1),tilecode(p2)
                c_edge, c_un, c_int = xor(c1, c2), c1|c2, c1&c2

                if (c_edge == 0) & (c_un == 0) return "p_on"
                elseif (c_edge == 12) & (c_un == c_edge) return "p_on"
                elseif c_edge == 3
                    if c_int == 0 return "p_on"
                    elseif c_int == 4 count += 1 end
                elseif c_edge == 15
                    x_int = ((y-y2)*(x1-x2)/(y1-y2))+x2
                    if x_int > x count += 1
                    elseif x_int == x return "p_on" end
                elseif (c_edge == 13) & ((c1==4) | (c2==4))
                        status, count = crossingTest(1,2,status,count)
                elseif (c_edge == 14) & ((c1==4) | (c2==4))
                        status, count = crossingTest(2,1,status,count)
                elseif c_edge == 7 count += 1
                elseif c_edge == 11 count = count
                elseif c_edge == 1
                    if c_int == 0 return "p_on"
                    elseif c_int == 4
                        status, count = crossingTest(1,2,status,count)
                    end
                elseif c_edge == 2
                    if c_int == 0 return "p_on"
                    elseif c_int == 4
                        status, count = crossingTest(2,1,status,count)
                    end
                elseif (c_edge == 4) & (c_un == c_edge) return "p_on"
                elseif (c_edge == 8) & (c_un == c_edge) return "p_on"
                elseif c_edge == 5
                    if (c1==0) | (c2==0) return "p_on"
                    else
                        status, count = crossingTest(1,2,status,count)
                    end
                elseif c_edge == 6
                    if (c1==0) | (c2==0) return "p_on"
                    else
                        status, count = crossingTest(2,1,status,count)
                    end
                elseif (c_edge == 9) & ((c1==0) | (c2==0)) return "p_on"
                elseif (c_edge == 10) & ((c1==0) | (c2==0)) return "p_on"
                end
            end

            if (round(count)%2)==1
                return "p_in"
            else
                return "p_out"
            end
        end
        return pointInPolygonClassification0
    end

    return pointInPolygonClassification(V, copEV)(point) == "p_in"
end

"""
    lar2obj(V::Points, cc::ChainComplex)

Triangulated OBJ string representation of the model passed as input.

Use this function to export LAR models into OBJ

# Example

```julia
	julia> cube_1 = ([0 0 0 0 1 1 1 1; 0 0 1 1 0 0 1 1; 0 1 0 1 0 1 0 1],
	[[1,2,3,4],[5,6,7,8],[1,2,5,6],[3,4,7,8],[1,3,5,7],[2,4,6,8]],
	[[1,2],[3,4],[5,6],[7,8],[1,3],[2,4],[5,7],[6,8],[1,5],[2,6],[3,7],[4,8]] )

	julia> cube_2 = Lar.Struct([Lar.t(0,0,0.5), Lar.r(0,0,pi/3), cube_1])

	julia> V, FV, EV = Lar.struct2lar(Lar.Struct([ cube_1, cube_2 ]))

	julia> V, bases, coboundaries = Lar.chaincomplex(V,FV,EV)

	julia> (EV, FV, CV), (copEV, copFE, copCF) = bases, coboundaries

	julia> FV # bases[2]
	18-element Array{Array{Int64,1},1}:
	 [1, 3, 4, 6]
	 [2, 3, 5, 6]
	 [7, 8, 9, 10]
	 [1, 2, 3, 7, 8]
	 [4, 6, 9, 10, 11, 12]
	 [5, 6, 11, 12]
	 [1, 4, 7, 9]
	 [2, 5, 11, 13]
	 [2, 8, 10, 11, 13]
	 [2, 3, 14, 15, 16]
	 [11, 12, 13, 17]
	 [11, 12, 13, 18, 19, 20]
	 [2, 3, 13, 17]
	 [2, 13, 14, 18]
	 [15, 16, 19, 20]
	 [3, 6, 12, 15, 19]
	 [3, 6, 12, 17]
	 [14, 16, 18, 20]

	julia> CV # bases[3]
	3-element Array{Array{Int64,1},1}:
	 [2, 3, 5, 6, 11, 12, 13, 14, 15, 16, 18, 19, 20]
	 [2, 3, 5, 6, 11, 12, 13, 17]
	 [1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 17]

	julia> copEV # coboundaries[1]
	34×20 SparseMatrixCSC{Int8,Int64} with 68 stored entries: ...

	julia> copFE # coboundaries[2]
	18×34 SparseMatrixCSC{Int8,Int64} with 80 stored entries: ...

	julia> copCF # coboundaries[3]
	4×18 SparseMatrixCSC{Int8,Int64} with 36 stored entries: ...

	objs = Lar.lar2obj(V'::Lar.Points, [coboundaries...])

	open("./two_cubes.obj", "w") do f
    	write(f, objs)
	end
```
"""
function lar2obj(V::Common.Points, cc::Common.ChainComplex)
    copEV, copFE, copCF = cc
	if size(V,2) > 3
		V = convert(Common.Points, V') # out V by rows
	end
    obj = ""
    for v in 1:size(V, 1)
        obj = string(obj, "v ",
    	round(V[v, 1], digits=6), " ",
    	round(V[v, 2], digits=6), " ",
    	round(V[v, 3], digits=6), "\n")
    end

    print("Triangulating")
    triangulated_faces = triangulate(V, cc[1:2])
    println("DONE")

    for c in 1:copCF.m
        obj = string(obj, "\ng cell", c, "\n")
        for f in copCF[c, :].nzind
            triangles = triangulated_faces[f]
            for tri in triangles
                #t = copCF[c, f] > 0 ? tri : tri[end:-1:1]
				t = tri
                obj = string(obj, "f ", t[1], " ", t[2], " ", t[3], "\n")
            end
        end
    end

    return obj
end

"""
	lar2obj(V::Lar.Points, TV::Lar.Cells)::String
```
```
"""
function lar2obj(V::Common.Points, TV::Common.Cells)
	obj = ""
    for v in 1:size(V, 1)
        obj = string(obj, "v ",
    	round(V[1,v], digits=6), " ",
    	round(V[2,v], digits=6), " ",
    	round(V[3,v], digits=6), "\n")
	end
	for tri in TV
		#t = copCF[c, f] > 0 ? tri : tri[end:-1:1]
		obj = string(obj, "f ", tri[1], " ", tri[2], " ", tri[3], "\n")
	end
end

"""
    obj2lar(path)

Read OBJ file at `path` and create a 2-skeleton as `Tuple{Points, ChainComplex}` from it.

This function does care about eventual internal grouping inside the OBJ file.
"""
function obj2lar(path)
    vs = Array{Float64, 2}(undef, 0, 3)
    edges = Array{Array{Array{Int, 1}, 1}, 1}()
    faces = Array{Array{Array{Int, 1}, 1}, 1}()
	push!(edges, Array{Array{Int, 1}, 1}[])
	push!(faces, Array{Array{Int, 1}, 1}[])
	g = 1

    open(path, "r") do fd
        for line in eachline(fd)
            elems = split(line)
            if length(elems) > 0
                if elems[1] == "v"
					# parse and store a vertex
                    x = parse(Float64, elems[2])
                    y = parse(Float64, elems[3])
                    z = parse(Float64, elems[4])
                    vs = [vs; x y z]

				elseif elems[1] == "f"
                    # Ignore the vertex tangents and normals
                    v1 = parse(Int, split(elems[2], "/")[1])
                    v2 = parse(Int, split(elems[3], "/")[1])
                    v3 = parse(Int, split(elems[4], "/")[1])

                    e1 = sort([v1, v2])
                    e2 = sort([v2, v3])
                    e3 = sort([v3, v1])

					push!(edges[g], e1)
					push!(edges[g], e2)
					push!(edges[g], e3)

                    push!(faces[g], sort([v1, v2, v3]))

				elseif elems[1] == "g"
					#start a new group of edges and faces
					#println(line)
					g += 1
					push!(edges, Array{Array{Int, 1}, 1}[])
					push!(faces, Array{Array{Int, 1}, 1}[])
				end
            end
        end
    end

	#return vs, build_cops(edges, faces)
	return convert(Common.Points, vs'), edges[2:end], faces[2:end]
end

"""
    binaryRange(n)

Generate the first `n` binary numbers in string padded for max `2^n` length
"""
function binaryRange(n)
    return string.(range(0, length=2^n), base=2, pad=n)
end


function space_arrangement(V::Common.Points, EV::Common.ChainOp, FE::Common.ChainOp, multiproc::Bool=false)

    fs_num = size(FE, 1)
    sp_idx = spatial_index(V, EV, FE)

    rV = Common.Points(undef, 0,3)
    rEV = SparseArrays.spzeros(Int8,0,0)
    rFE = SparseArrays.spzeros(Int8,0,0)

    if (multiproc == true)
        in_chan = Distributed.RemoteChannel(()->Channel{Int64}(0))
        out_chan = Distributed.RemoteChannel(()->Channel{Tuple}(0))

        @async begin
            for sigma in 1:fs_num
                put!(in_chan, sigma)
            end
            for p in Distributed.workers()
                put!(in_chan, -1)
            end
        end

        for p in Distributed.workers()
            @async Base.remote_do(
                frag_face_channel, p, in_chan, out_chan, V, EV, FE, sp_idx)
        end

        for sigma in 1:fs_num
            rV, rEV, rFE = skel_merge(rV, rEV, rFE, take!(out_chan)...)
        end

    else

#       for sigma in 1:fs_num
#           # print(sigma, "/", fs_num, "\r")
#           nV, nEV, nFE = Lar.Arrangement.frag_face(
#           	V, EV, FE, sp_idx, sigma)
#           a,b,c = Lar.skel_merge(
#           	rV, rEV, rFE, nV, nEV, nFE)
#           rV=a; rEV=b; rFE=c
#       end

	depot_V = Array{Array{Float64,2},1}(undef,fs_num)
	depot_EV = Array{Common.ChainOp,1}(undef,fs_num)
	depot_FE = Array{Common.ChainOp,1}(undef,fs_num)
       for sigma in 1:fs_num
           print(sigma, "/", fs_num, "\r")
           nV, nEV, nFE = frag_face( V, EV, FE, sp_idx, sigma)
           depot_V[sigma] = nV
           depot_EV[sigma] = nEV
           depot_FE[sigma] = nFE
       end
	rV = vcat(depot_V...)
	rEV = SparseArrays.blockdiag(depot_EV...)
	rFE = SparseArrays.blockdiag(depot_FE...)
Verbose = true

    end

if Verbose
	println("\npre congruence >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
	@show rV;
	@show SparseArrays.findnz(rEV);
	@show SparseArrays.findnz(rFE);
	println("ciao pre congruence <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n")
end
rV, rcopEV, rcopFE = merge_vertices(rV, rEV, rFE)
#V, EV, FV, FE  = Lar.chaincongruence(Matrix(rV'), rEV::Lar.ChainOp, rFE::Lar.ChainOp; epsilon=0.0001)
#VV = [[k] for k=1:size(V,2)]
#GL.VIEW(push!(GL.numbering(.5)((V,Lar.Cells[VV,EV,FV]), GL.COLORS[1], 0.5),GL.GLFrame2));
#rV, rEV, rFE = Lar.Points(V'), Lar.lar2cop(EV), Lar.lar2cop(FE)

#function arrange3Dfaces(V, copEV, copFE)
#EVs = Lar.FV2EVs(copEV, copFE) # polygonal face fragments
#
#triangulated_faces = Lar.triangulate2D(V, [copEV, copFE])
#FVs = convert(Array{Lar.Cells}, triangulated_faces)
#V = convert(Lar.Points,V')
#return V,FVs,EVs
#end
#V,FVs,EVs = arrange3Dfaces(rV, rEV, rFE);
#GL.VIEW(GL.GLExplode(V,FVs,1.1,1.1,1.1,99,1));
#GL.VIEW(GL.GLExplode(V,EVs,1.5,1.5,1.5,99,1));


	if Verbose
		println("\npost congruence >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
		@show rV;
		@show SparseArrays.findnz(rcopEV);
		@show SparseArrays.findnz(rcopFE);
		println("ciao post congruence <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n")
	end

    #rcopCF = Arrangement.minimal_3cycles(rV, rcopEV, rcopFE)
    rcopCF = build_copCF(rV, rcopEV, rcopFE)

    return rV, rcopEV, rcopFE, rcopCF

	if Verbose
		println("\npost arrangement >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
		@show rV;
		@show SparseArrays.findnz(rEV);
		@show SparseArrays.findnz(rFE);
		println("ciao post arrangement <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n")
	error("STOP")
	end

end


function merge_vertices(V::Common.Points, EV::Common.ChainOp, FE::Common.ChainOp, err=1e-4)
   vertsnum = size(V, 1)
   edgenum = size(EV, 1)
   facenum = size(FE, 1)
   newverts = zeros(Int, vertsnum)
   # KDTree constructor needs an explicit array of Float64
   V = Array{Float64,2}(V)
   W = convert(Common.Points, Common.transpose(V))
   kdtree = KDTree(W)
# remove vertices congruent to a single representative
   todelete = []
   i = 1
   for vi in 1:vertsnum
       if !(vi in todelete)
           nearvs = inrange(kdtree, V[vi, :], err)
           newverts[nearvs] .= i
           nearvs = setdiff(nearvs, vi)
           todelete = union(todelete, nearvs)
           i = i + 1
       end
   end
   nV = V[setdiff(collect(1:vertsnum), todelete), :]
   V[30,:] = V[26,:] #<<<<<<<<<<<<<<<<<< TEST

   # translate edges to take congruence into account
   edges = Array{Tuple{Int, Int}, 1}(undef, edgenum)
   oedges = Array{Tuple{Int, Int}, 1}(undef, edgenum)
   for ei in 1:edgenum
       v1, v2 = EV[ei, :].nzind
       edges[ei] = Tuple{Int, Int}(sort([newverts[v1], newverts[v2]]))
       oedges[ei] = Tuple{Int, Int}(sort([v1, v2]))
   end
   nedges = union(edges)
   # remove edges of zero length
   nedges = filter(t->t[1]!=t[2], nedges)
   nedgenum = length(nedges)
   nEV = spzeros(Int8, nedgenum, size(nV, 1))

   etuple2idx = Dict{Tuple{Int, Int}, Int}()
   for ei in 1:nedgenum
   	begin
       	nEV[ei, collect(nedges[ei])] .= 1
       	nEV
       end
       etuple2idx[nedges[ei]] = ei
   end
   for e in 1:nedgenum
   	v1,v2 = findnz(nEV[e,:])[1]
   	nEV[e,v1] = -1; nEV[e,v2] = 1
   end

   # compute new faces to take congruence into account
   faces = [[
       map(x->newverts[x], FE[fi, ei] > 0 ? oedges[ei] : reverse(oedges[ei]))
       for ei in FE[fi, :].nzind
   ] for fi in 1:facenum]


   visited = []
   function filter_fn(face)

       verts = []
       map(e->verts = union(verts, collect(e)), face)
       verts = Set(verts)

       if !(verts in visited)
           push!(visited, verts)
           return true
       end
       return false
   end

   nfaces = filter(filter_fn, faces)

   nfacenum = length(nfaces)
   nFE = spzeros(Int8, nfacenum, size(nEV, 1))

   for fi in 1:nfacenum
       for edge in nfaces[fi]
           ei = etuple2idx[Tuple{Int, Int}(sort(collect(edge)))]
           nFE[fi, ei] = sign(edge[2] - edge[1])
       end
   end

   return Common.Points(nV), nEV, nFE
end


###  2D triangulation
"""
	obj2lar2D(path::AbstractString)::Lar.LARmodel

Read a *triangulation* from file, given its `path`. Return a `LARmodel` object
"""
function obj2lar2D(path::AbstractString)::Common.LARmodel
    vs = Array{Float64, 2}(undef, 0, 3)
    edges = Array{Array{Int, 1}, 1}()
    faces = Array{Array{Int, 1}, 1}()

    open(path, "r") do fd
		for line in eachline(fd)
			elems = split(line)
			if length(elems) > 0
				if elems[1] == "v"
					x = parse(Float64, elems[2])
					y = parse(Float64, elems[3])
					z = parse(Float64, elems[4])
					vs = [vs; x y z]
				elseif elems[1] == "f"
					# Ignore the vertex tangents and normals
					v1 = parse(Int, elems[2])
					v2 = parse(Int, elems[3])
					v3 = parse(Int, elems[4])
					append!(edges, map(sort,[[v1,v2],[v2,v3],[v3,v1]]))
					push!(faces, [v1, v2, v3])
				end
				edges = collect(Set(edges))
			end
		end
	end
    return (vs, [edges,faces])
end


"""
	lar2obj2D(V::Lar.Points,
			cc::Lar.ChainComplex)::String

Produce a *triangulation* from a `LARmodel`. Return a `String` object
"""
function lar2obj2D(V::Common.Points, cc::Common.ChainComplex)::String
    @assert length(cc) == 2
    copEV, copFE = cc
    V = [V zeros(size(V, 1))]

    obj = ""
    for v in 1:size(V, 1)
        	obj = string(obj, "v ",
        	round(V[v, 1]; digits=6), " ",
        	round(V[v, 2]; digits=6), " ",
        	round(V[v, 3]; digits=6), "\n")
    end

    #triangulated_faces = triangulate2D(V, cc)
    triangulated_faces = triangulate(V, cc)

	obj = string(obj, "\n")
	for f in 1:copFE.m
		triangles = triangulated_faces[f]
		for tri in triangles
			t = tri
			#t = copCF[c, f] > 0 ? tri : tri[end:-1:1]
			obj = string(obj, "f ", t[1], " ", t[2], " ", t[3], "\n")
		end
	end

    return obj
end


#TODO: finish by using a string as an IObuffer
#"""
#	lar2tria2lar(V::Lar.Points, cc::Lar.ChainComplex)::Lar.LARmodel
#
#Return a triangulated `LARmodel` starting from a stadard LARmodel.
#Useful for colour drawing a complex of non-convex cells.
#
#"""
#function lar2tria2lar(V::Lar.Points, cc::Lar.ChainComplex)::Lar.LARmodel
#	obj = Lar.lar2obj2D(V::Lar.Points, cc::Lar.ChainComplex)
#	vs, (edges,faces) = Lar.obj2lar2D(obj::AbstractString)::Lar.LARmodel
#	return (vs, [edges,faces])::Lar.LARmodel
#end




"""
	triangulate2D(V::Lar.Points,
			cc::Lar.ChainComplex)::Array{Any, 1}

Compute a *CDT* for each face of a `ChainComplex`. Return an `Array` of triangles.
"""
function triangulate2D(V::Common.Points, cc::Common.ChainComplex)::Array{Any, 1}
    copEV, copFE = cc
    triangulated_faces = Array{Any, 1}(undef, copFE.m)
    if size(V,2)==2
		V = [V zeros(size(V,1),1)]
	end

	polygons,edgecycles = faces2polygons(copEV, copFE) #new

    for f in 1:copFE.m
        edges_idxs = copFE[f, :].nzind
        edge_num = length(edges_idxs)
        edges = Array{Int64,1}[] #zeros(Int64, edge_num, 2)

		# fv = Lar.buildFV(copEV, copFE[f, :])
		fv = union(polygons[f]...)
        vs = V[fv, :]
		edges = union(edgecycles[f]...)
        edges = convert(Array{Int64,2}, hcat(edges...)')

		# triangulated_faces[f] = Triangle.constrained_triangulation(
        # 	vs, fv, edges, fill(true, edge_num))
		v = convert(Common.Points, vs'[1:2,:])
		vmap = Dict(zip(fv,1:length(fv))) # vertex map
		mapv = Dict(zip(1:length(fv),fv)) # inverse vertex map
		ev = [[vmap[e] for e in edges[k,:]] for k=1:size(edges,1)]
		trias = triangulate2d(v,ev)
		triangulated_faces[f] = [[mapv[v] for v in tria] for tria in trias]

        tV = V[:, 1:2]

        area = face_area(tV, copEV, copFE[f, :])
        if area < 0
            for i in 1:length(triangulated_faces[f])
                triangulated_faces[f][i] = triangulated_faces[f][i][end:-1:1]
            end
        end
    end

    return triangulated_faces
end


"""
	lar2cop(CV::Lar.Cells)::Lar.ChainOp

Convert an array of array of integer indices to vertices into a sparse matrix.

# Examples

For a single 3D unit cube we get:

```
julia> V,(VV,EV,FV,CV) = Lar.cuboid([1,1,1],true);

julia> Matrix(Lar.lar2cop(EV))
12×8 Array{Int8,2}:
 1  1  0  0  0  0  0  0
 0  0  1  1  0  0  0  0
 0  0  0  0  1  1  0  0
 0  0  0  0  0  0  1  1
 1  0  1  0  0  0  0  0
 0  1  0  1  0  0  0  0
 0  0  0  0  1  0  1  0
 0  0  0  0  0  1  0  1
 1  0  0  0  1  0  0  0
 0  1  0  0  0  1  0  0
 0  0  1  0  0  0  1  0
 0  0  0  1  0  0  0  1

julia> Matrix(Lar.lar2cop(FV))
6×8 Array{Int8,2}:
 1  1  1  1  0  0  0  0
 0  0  0  0  1  1  1  1
 1  1  0  0  1  1  0  0
 0  0  1  1  0  0  1  1
 1  0  1  0  1  0  1  0
 0  1  0  1  0  1  0  1

julia> Matrix(Lar.lar2cop(CV))
1×8 Array{Int8,2}:
 1  1  1  1  1  1  1  1
```
"""
function lar2cop(CV::Common.Cells)::Common.ChainOp
	I = Int64[]; J = Int64[]; Value = Int8[];
	for k=1:size(CV,1)
		n = length(CV[k])
		append!(I, k * ones(Int64, n))
		append!(J, CV[k])
		append!(Value, ones(Int64, n))
	end
	return SparseArrays.sparse(I,J,Value)
end


"""
	cop2lar(cop::Lar.ChainOp)::Lar.Cells

Convert a sparse array of type `ChainOp` into an array of array of type `Cells`.

Notice that `cop2lar` is the inverse function of `lar2cop`. their composition is the identity function.

# Example

```
julia> V,(VV,EV,FV,CV) = Lar.cuboid([1,1,1],true);

julia> Lar.cop2lar(Lar.lar2cop(EV))
12-element Array{Array{Int64,1},1}:
 [1, 2]
 [3, 4]
   ...
 [2, 6]
 [3, 7]
 [4, 8]

julia> Lar.cop2lar(Lar.lar2cop(FV))
6-element Array{Array{Int64,1},1}:
 [1, 2, 3, 4]
 [5, 6, 7, 8]
 [1, 2, 5, 6]
 [3, 4, 7, 8]
 [1, 3, 5, 7]
 [2, 4, 6, 8]

julia> Lar.cop2lar(Lar.lar2cop(CV))
1-element Array{Array{Int64,1},1}:
 [1, 2, 3, 4, 5, 6, 7, 8]
```
"""
function cop2lar(cop::Common.ChainOp)::Common.Cells
	[findnz(cop[k,:])[1] for k=1:size(cop,1)]
end


function FV2EVs(copEV::Common.ChainOp, copFE::Common.ChainOp)
	EV = [findnz(copEV[k,:])[1] for k=1:size(copEV,1)]
	FE = [findnz(copFE[k,:])[1] for k=1:size(copFE,1)]
	EVs = [[EV[e] for e in fe] for fe in FE]
	return EVs
end


"""
	compute_FV( copEV::Lar.ChainOp, copFE::Lar.ChainOp )::Lar.Cells

Compute the `FV` array of type `Lar.Cells` from two `Lar.ChainOp`, via
sparse array product.  To be generalized to open 2-manifolds.
"""
function compute_FV( copEV::Common.ChainOp, copFE::Common.ChainOp )
	# TODO: generalize for open 2-manifolds
	kFV = (x->div(x,2)).(abs.(copFE) * abs.(copEV)) # works only for closed surfaces
	FV = [SparseArrays.findnz(kFV[k,:])[1] for k=1:size(kFV,1)]
	return FV
end



"""
    constrained_triangulation2D(V::Lar.Points, EV::Lar.Cells) -> Lar.Cells
"""
function constrained_triangulation2D(V::Common.Points, EV::Common.Cells)
	triin = Triangulate.TriangulateIO()
	triin.pointlist = V
	triin.segmentlist = hcat(EV...)
	(triout, vorout) = Triangulate.triangulate("pQ", triin)
	trias = Array{Int64,1}[c[:] for c in eachcol(triout.trianglelist)]
	return trias
end


"""
 	triangulate2d(V::Lar.Points, EV::Lar.Cells)

"""
function triangulate2d(V::Common.Points, EV::Common.Cells)
   	 # data for Constrained Delaunay Triangulation (CDT)
   	 points = convert(Array{Float64,2}, V')
	 # points_map = Array{Int64,1}(collect(1:1:size(points)[1]))
   	 # edges_list = convert(Array{Int64,2}, hcat(EV...)')
   	 # edge_boundary = [true for k=1:size(edges_list,1)] ## dead code !!
	trias = constrained_triangulation2D(V, EV)

 	#Triangle.constrained_triangulation(points,points_map,edges_list)
	innertriangles = Array{Int64,1}[]
	for (u,v,w) in trias
		point = (points[u,:]+points[v,:]+points[w,:])./3
		copEV = lar2cop(EV)
		inner = point_in_face(point, points, copEV)
		if inner
			push!(innertriangles,[u,v,w])
		end
	end
    return innertriangles
end

function submanifold_mapping(vs)
    u1 = vs[2,:] - vs[1,:]
    u2 = vs[3,:] - vs[1,:]
    u3 = Common.cross(u1, u2)
    T = Matrix{Float64}(Common.I, 4, 4)
    T[4, 1:3] = - vs[1,:]
    M = Matrix{Float64}(Common.I, 4, 4)
    M[1:3, 1:3] = [u1 u2 u3]
    return T*M
end

function spatial_index(V::Common.Points, EV::Common.ChainOp, FE::Common.ChainOp)
    d = 3
    faces_num = size(FE, 1)
    IntervalsType = IntervalValue{Float64, Int64}
    boxes1D = Array{IntervalsType, 2}(undef, 0, d)

    for fi in 1:faces_num
        vidxs = (abs.(FE[fi:fi,:])*abs.(EV))[1,:].nzind
        intervals = map((l,u)->IntervalsType(l,u,fi),
        	bbox(V[vidxs, :])...)
        boxes1D = vcat(boxes1D, intervals)
    end
    trees = mapslices(IntervalTree{Float64, IntervalsType}, sort(boxes1D; dims=1), dims=1)

    function intersect_intervals(intervals)
        cells = Array{Int64,1}[]
        for axis in 1:d
            vs = map(i->i.value, intersect(trees[axis], intervals[axis]))
            push!(cells, vs)
        end
        mapreduce(x->x, intersect, cells)
    end

    mapping = Array{Int64,1}[]
    for fi in 1:faces_num
        cell_indexes = setdiff(intersect_intervals(boxes1D[fi, :]), [fi])
        push!(mapping, cell_indexes)
    end

    mapping
end

function face_int(V::Common.Points, EV::Common.ChainOp, face::Common.Cell)
    vs = buildFV(EV, face)
    retV = Common.Points(undef, 0, 3)

    visited_verts = []
    for i in 1:length(vs)
        o = V[vs[i],:]
        j = i < length(vs) ? i+1 : 1
        d = V[vs[j],:] - o

        err = 10e-8
        # err = 10e-4
        if !(-err < d[3] < err)

            alpha = -o[3] / d[3]

            if -err <= alpha <= 1+err
                p = o + alpha*d

                if -err < alpha < err || 1-err < alpha < 1+err
                    if !(vin(p, visited_verts))
                        push!(visited_verts, p)
                        retV = [retV; reshape(p, 1, 3)]
                    end
                else
                    retV = [retV; reshape(p, 1, 3)]
                end
            end
        end

    end

    vnum = size(retV, 1)


    if vnum == 1
        vnum = 0
        retV = Common.Points(undef, 0, 3)
    end
    enum = (÷)(vnum, 2)
    retEV = spzeros(Int8, enum, vnum)

    for i in 1:enum
        retEV[i, 2*i-1:2*i] = [-1, 1]
    end

    retV, retEV
end



"""
	frag_face_channel(in_chan, out_chan, V, EV, FE, sp_idx)
Parallel fragmentation of faces in `FE` against faces in `sp_idx`.
"""
function frag_face_channel(in_chan, out_chan, V, EV, FE, sp_idx)
    run_loop = true
    while run_loop
        sigma = take!(in_chan)
        if sigma != -1
            put!(out_chan, frag_face(V, EV, FE, sp_idx, sigma))
        else
            run_loop = false
        end
    end
end



"""
	frag_face(V, EV, FE, sp_idx, sigma)
`sigma` face fragmentation against faces in `sp_idx[sigma]`
"""
function frag_face(V, EV, FE, sp_idx, sigma)

    vs_num = size(V, 1)

	# 2D transformation of sigma face
    sigmavs = (abs.(FE[sigma:sigma,:]) * abs.(EV))[1,:].nzind
    sV = V[sigmavs, :]
    sEV = EV[FE[sigma, :].nzind, sigmavs]
    M = submanifold_mapping(sV)
    tV = ([V ones(vs_num)]*M)[:, 1:3]  # folle convertire *tutti* i vertici
    sV = tV[sigmavs, :]
    # sigma face intersection with faces in sp_idx[sigma]
    for i in sp_idx[sigma]
        tmpV, tmpEV = face_int(tV, EV, FE[i, :])
		sV, sEV
        sV, sEV = skel_merge(sV, sEV, tmpV, tmpEV)
    end

    # computation of 2D arrangement of sigma face
    sV = sV[:, 1:2]
    nV, nEV, nFE = planar_arrangement(sV, sEV, sparsevec(ones(Int8, length(sigmavs))))
    if nV == nothing ## not possible !! ... (each original face maps to its decomposition)
        return [], spzeros(Int8, 0,0), spzeros(Int8, 0,0)
    end
    nvsize = size(nV, 1)
    nV = [nV zeros(nvsize) ones(nvsize)]*inv(M)[:, 1:3] ## ????

    return nV, nEV, nFE
end
