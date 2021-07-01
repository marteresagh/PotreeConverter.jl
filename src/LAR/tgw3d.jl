choose(marks) = findfirst(x -> x<2, marks)

# Implementation of *TGW algorithm*
function build_copCF( V::Matrix{Float64}, EV::Common.ChainOp, FE::Common.ChainOp)
	# initialization
	m,n,marks,FV = initialization(V, EV, FE)
	# building the buondary matrix columns (basis 2-cycles)
	FC = mainloop(marks,n,V,EV,FE,FV)
	# finalization: boundary -> coboundary
	CF = convert(Common.ChainOp, FC')
	return CF
end

# Initializations
function initialization(V, EV, FE)
	n,m = size(FE)
	marks = zeros(Int8,n);
	aI,aJ,aX = SparseArrays.findnz(FE * EV)
	FV = SparseArrays.sparse(aI,aJ,ones(Int8,length(aX)))
	return m,n,marks,FV
end

# Main loop adding stepwise one FC's column
function mainloop(marks,n,V,EV,FE,FV)
	FC = convert(SparseMatrixCSC{Int8, Int64}, spzeros(n,0))
	while sum(marks) < 2n
		# select a (d−1)-cell, "seed" of the column extraction
		σ = choose(marks)
		cd1 = marks[σ] > 0 ? sparsevec([σ], Int8[-1], n) : sparsevec([σ], Int8[1], n)
		# compute boundary cd2 of seed cell
		cd2 = transpose(transpose(cd1) * FE)
		corolla = constructioncycle(cd2,marks,V,EV,FE,FV,cd1)
		FC = newcolumn(cd1,marks,FC)
	end
	return FC
end

function newcolumn(cd1,marks,FC)
	# update the counters of used cells
	for σ ∈ SparseArrays.findnz(cd1)[1]
		marks[σ] += 1  end
	# append a new column: FC += cd1
	FC = [FC cd1]
	return 	FC
end

function constructioncycle(cd2,marks,V,EV,FE,FV,cd1)
	FV,EV,fe = map( cop2lar,[FV,EV,FE])
	m = length(cd2); W = Matrix(V')
	# loop until (boundary) cd2 becomes empty
	global corolla
	while nnz(cd2)≠0
		corolla = sparsevec([], Int8[], m)
		for τ ∈ (.*)(SparseArrays.findnz(cd2)...)
			#compute the  coboundary
			tau = sparsevec([abs(τ)], [sign(τ)], m)
			bd1 = FE * tau
			cells2D = SparseArrays.findnz(bd1)[1]
			# compute the  support
			inters = intersect(cells2D, SparseArrays.findnz(cd1)[1])
			pivot = inters ≠ [] ? inters[1] : error("no pivot")
			# compute the new adj cell
			fan = ord(abs(τ),bd1,W,FV,EV,fe) # ord(pivot,bd1)
			adj = τ > 0 ? mynext(fan,pivot) : myprev(fan,pivot)
			# orient adj
			corolla[adj] = FE[adj,abs(τ)] ≠ FE[pivot,abs(τ)] ? cd1[pivot] : -cd1[pivot]
		end
		# insert corolla cells in current cd1
		for (k,val) in zip(SparseArrays.findnz(corolla)...)
			cd1[k] = val  end
		# compute again the boundary of cd1
		cd2 = transpose(transpose(cd1) * FE)
	end
	return corolla
end
