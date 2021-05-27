"""
	CWNode

Single node of Comaptree.
"""
mutable struct CWNode
	level::Int
	index::Int
	dict::Dict{Vector{Float64},Vector{Vector{Float64}}}
	parent::Union{Nothing,CWNode}
	children::Vector{Union{Nothing,CWNode}}
end


"""
	ComaptreeWriter

Metastructure of isomorphic tree of Potree, compatree.
"""
struct ComaptreeWriter
    root::CWNode
end
