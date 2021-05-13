function SparseGrid(aabb::pAABB, spacing::Float64)
	width =	Int(floor(aabb.size[1] / (spacing * cellSizeFactor) ))
	height = Int(floor(aabb.size[2] / (spacing * cellSizeFactor) ))
	depth =	Int(floor(aabb.size[3] / (spacing * cellSizeFactor) ))
	squaredSpacing = spacing * spacing;
	numAccepted = 0
	map = Dict{Int64,GridCell}()
	return SparseGrid(map,
				width,
				height,
				depth,
				aabb,
				squaredSpacing,
				numAccepted
				)
end

function add(sparseGrid::SparseGrid,p::Vector{Float64})::Bool

	aabb = sparseGrid.aabb
	width = sparseGrid.width
	height = sparseGrid.height
	depth = sparseGrid.depth

	nx = Int(floor(width*(p[1] - aabb.min[1]) / aabb.size[1]))
	ny = Int(floor(width*(p[2] - aabb.min[2]) / aabb.size[2]))
	nz = Int(floor(width*(p[3] - aabb.min[3]) / aabb.size[3]))

	i = min(nx, width-1);
	j = min(ny, height-1);
	k = min(nz, depth-1);


	index = GridIndex(i,j,k)
	key = (k << 40) | (j << 20) | i
	if !haskey(sparseGrid.map,key)
		it = GridCell(sparseGrid, index)
		sparseGrid.map[key] = it
	else
		it = sparseGrid.map[key]
	end

	if isDistant(sparseGrid, p, it)
		add(it,p)
		sparseGrid.numAccepted+=1
		return true
	else
		return false
	end
end

function isDistant(sparseGrid::SparseGrid, p::Vector{Float64}, cell::GridCell)::Bool
	if !isDistant(cell,p,sparseGrid.squaredSpacing)
		return false
	end

	for neighbour in cell.neighbours
		if !isDistant(neighbour,p, sparseGrid.squaredSpacing)
			return false
		end
	end

	return true
end

function addWithoutCheck(sparseGrid::SparseGrid, p::Vector{Float64}, potreeWriter::PotreeWriter)
	aabb = sparseGrid.aabb
	width = sparseGrid.width
	height = sparseGrid.height
	depth = sparseGrid.depth

	nx = Int(floor(width*(p[1] - aabb.min[1]) / aabb.size[1]))
	ny = Int(floor(height*(p[2] - aabb.min[2]) / aabb.size[2]))
	nz = Int(floor(depth*(p[3] - aabb.min[3]) / aabb.size[3]))

	i = min(nx, width-1)
	j = min(ny, height-1)
	k = min(nz, depth-1)

	index = GridIndex(i,j,k)
	key = k << 40 | j << 20 | i

	if !haskey(sparseGrid.map,key)
		it = GridCell(sparseGrid, index)
		sparseGrid.map[key] = it
	else
		it = grid.map[key]
	end

	add(it,p,potreeWriter)
end

#
# function isDistant(p::Vector{Float64}, cell::GridCell, squaredSpacing::Float64)::Bool
# 	if !isDistant(cell,p,squaredSpacing)
# 		return false
# 	end
#
# 	for neighbour in cell.neighbours
# 		if !isDistant(neighbour,p, squaredSpacing)
# 			return false
# 		end
# 	end
#
# 	return true
# end

#
# function willBeAccepted(sparseGrid::SparseGrid,p::Vector{Float64}, squaredSpacing::Float64)::Bool
# 	aabb = sparseGrid.aabb
# 	width = sparseGrid.width
# 	height = sparseGrid.height
# 	depth = sparseGrid.depth
#
# 	nx = Int(floor(width*(p[1] - aabb.min[1]) / aabb.size[1]))
# 	ny = Int(floor(width*(p[2] - aabb.min[2]) / aabb.size[2]))
# 	nz = Int(floor(width*(p[3] - aabb.min[3]) / aabb.size[3]))
#
# 	i = min(nx, width-1);
# 	j = min(ny, height-1);
# 	k = min(nz, depth-1);
#
# 	# GridIndex index(i,j,k);
# 	# long long key = ((long long)k << 40) | ((long long)j << 20) | (long long)i;
# 	# SparseGrid::iterator it = find(key);
# 	# if(it == end()){
# 	# 	it = this->insert(value_type(key, new GridCell(this, index))).first;
# 	# }
# 	#
# 	# if(isDistant(p, it->second, squaredSpacing)){
# 	# 	return true;
# 	# }else{
# 	# 	return false;
# 	# }
# end
