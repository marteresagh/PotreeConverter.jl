function operator_minor(this::GridIndex, b::GridIndex)
	if this.i < b.i
		return true
	elseif this.i == b.i && this.j < b.j
		return true
	elseif this.i == b.i && this.j == b.j && this.k < b.k
		return true
	end
	return false
end

function GridCell(grid::SparseGrid, index::GridIndex, this_cell::GridCell)

	#TODO indici da rivedere
	for i in max(index.i-1,0):min(grid.width-1,index.i+1)
		for j in max(index.j-1,0):min(grid.height-1,index.j+1)
			for k in max(index.k-1,0):min(grid.depth-1,index.k+1)
				key = (k << 40) | (j << 20) | i
				it = get(grid.map,key,nothing)
				if !isnothing(it)
					neighbour = it
					if neighbour != this_cell
						push!(this_cell.neighbours,neighbour)
						push!(neighbour.neighbours,this_cell)
					end
				end
			end
		end
	end
end

function add(cell::GridCell,p::Point)
	push!(cell.points,p)
end

function isDistant(cell::GridCell, p::Vector{Float64}, squaredSpacing::Float64)
	for point in cell.points
		if squaredDistanceTo(p,point) < squaredSpacing
			return false
		end
	end

	return true
end
