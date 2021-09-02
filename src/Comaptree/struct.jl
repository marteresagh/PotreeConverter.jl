"""
	CWNode

Single node of Comaptree.

# Constructors
```jldoctest
CWNode()::CWNode
CWNode(index::Int, level::Int)::CWNode
```

# Fields
```jldoctest
level::Int
index::Int
dict::Dict{Vector{Float64},Vector{Vector{Float64}}}
parent::Union{Nothing,CWNode}
children::Vector{Union{Nothing,CWNode}}
```
"""
mutable struct CWNode
	level::Int
	index::Int
	# dict::Dict{Vector{Float64},Vector{Vector{Float64}}} # [a,b,c] => [d1,d2,d3,d4,...,dn]

	# cells::Vector{Common.LAR}
	hyperplanes::Vector{Detection.Hyperplane}

	parent::Union{Nothing,CWNode}
	children::Vector{Union{Nothing,CWNode}}
end


"""
	ComaptreeWriter

Metastructure of isomorphic tree of Potree, compatree.

# Constructors
```jldoctest
ComaptreeWriter(root::CWNode)
```

# Fields
```jldoctest
root::CWNode
```
"""
struct ComaptreeWriter
    root::CWNode
end
