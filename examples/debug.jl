using PotreeConverter
using Common
using FileManager
# dato un potree e partendo dalle foglie devo continuare a costruire nodi se questi hanno più di un piano

potree = raw"C:\Users\marte\Documents\Julia_package\UTILS\potreeoriginale\MURI"
PotreeConverter.expand(potree, PotreeConverter.split_leaf)


cmtree = PotreeConverter.potree2comaptree(potree)

# # ############################
trie = FileManager.potree2trie(potree)
leaf_files = FileManager.get_leaf(trie)


function postorder(root::PotreeConverter.CWNode, callback::Function)
	 if !isempty(root.children)
		 for child in root.children
			 if !isnothing(child)
			 	postorder(child, callback)
			end
		 end
		 callback(root)
	 end
end

printname(node::PotreeConverter.CWNode) = println(PotreeConverter.name(node))
postorder(cmtree.root, printname)
