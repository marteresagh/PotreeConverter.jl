function CWNode()
	level = 0
	index = -1
    dict = Dict{Vector{Float64},Vector{Vector{Float64}}}()
    parent = nothing
    children = Union{Nothing,CWNode}[]
    return CWNode(level,index,dict,parent,children)
end

function CWNode(index::Int, level::Int)::CWNode
	dict = Dict{Vector{Float64},Vector{Vector{Float64}}}()
    parent = nothing
    children = Union{Nothing,CWNode}[]
    return CWNode(level, index, dict, parent, children)
end

function name(node::CWNode)::String
	if isnothing(node.parent)
		return "r"
	else
		return name(node.parent)*string(node.index)
	end
end

function isLeafNode(node::CWNode)::Bool
	return isempty(node.children)
end

function isInnerNode(node::CWNode)::Bool
	return length(node.children) > 0
end


function findNode(node::CWNode, ref_name::String)
	thisName = name(node)

	if length(ref_name) == length(thisName)
		return ref_name == thisName ? node : nothing
	elseif length(ref_name) > length(thisName)
		childIndex = parse(Int,ref_name[length(thisName)+1])
		if !isLeafNode(node) && !isnothing(node.children[childIndex+1])
			return findNode(node.children[childIndex+1],ref_name);
		else
			return nothing
		end
	else
		return nothing
	end
end

function traverse(this_node::PotreeConverter.CWNode, callback::Function)
	callback(this_node)
	for child in this_node.children
		if !isnothing(child)
			traverse(child, callback)
		end
	end
end


"""
	postorder(root::PotreeConverter.CWNode, callback::Function)

If the `node` is not a leaf, then postorder traverse all children of `node`, else elaborate the `node` dataset.
"""
function postorder(node::PotreeConverter.CWNode, callback::Function)
	 if !isempty(node.children)
		 for child in node.children
			 if !isnothing(child)
			 	postorder(child, callback)
			end
		 end
	 end
	 callback(node)
end
