
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



function isDistant(p::Vector{Float64}, cell::GridCell, squaredSpacing::Float64)::Bool
	if !isDistant(cell,p,squaredSpacing)
		return false
	end

	for neighbour in cell.neighbours
		if !isDistant(neighbour,p, squaredSpacing)
			return false
		end
	end

	return true
end


function willBeAccepted(sparseGrid::SparseGrid,p::Vector{Float64}, squaredSpacing::Float64)::Bool
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

	# GridIndex index(i,j,k);
	# long long key = ((long long)k << 40) | ((long long)j << 20) | (long long)i;
	# SparseGrid::iterator it = find(key);
	# if(it == end()){
	# 	it = this->insert(value_type(key, new GridCell(this, index))).first;
	# }
	#
	# if(isDistant(p, it->second, squaredSpacing)){
	# 	return true;
	# }else{
	# 	return false;
	# }
}
