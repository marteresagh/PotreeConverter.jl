using PotreeConverter
using FileManager

mutable struct Node
	value::Int
	children::Vector{Node}
end


this_node = Node(1,[Node(2,Node[]), Node(3,Node[])])

function callback(node::Node)
	node.value = 0
end

function traverse(this_node::Node, callback::Function)
	callback(this_node)
	for child in this_node.children
		traverse(child, callback)
	end
end

 traverse(this_node, callback)
