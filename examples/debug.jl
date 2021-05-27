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

function test_tree()
	r = PotreeConverter.CWNode()
	r0 = PotreeConverter.CWNode(0,1)
	r1 = PotreeConverter.CWNode(1,1)
	r01 = PotreeConverter.CWNode(1,2)
	r010 = PotreeConverter.CWNode(0,3)
	r011 = PotreeConverter.CWNode(1,3)
	r11 = PotreeConverter.CWNode(1,2)
	r12 = PotreeConverter.CWNode(2,2)
	r121 = PotreeConverter.CWNode(1,3)
	r122 = PotreeConverter.CWNode(2,3)
	r123 = PotreeConverter.CWNode(3,3)
	r124 = PotreeConverter.CWNode(4,3)
	r.children = Vector{Union{Nothing,PotreeConverter.CWNode}}(nothing,8)
	r.children[1] = r0; r.children[2] = r1;
	r0.children = Vector{Union{Nothing,PotreeConverter.CWNode}}(nothing,8)
	r0.children[2] = r01;
	r1.children = Vector{Union{Nothing,PotreeConverter.CWNode}}(nothing,8)
	r1.children[2] = r11; r1.children[3] = r12;
	r01.children = Vector{Union{Nothing,PotreeConverter.CWNode}}(nothing,8)
	r01.children[1] = r010; r01.children[2] = r011;
	r12.children = Vector{Union{Nothing,PotreeConverter.CWNode}}(nothing,8)
	r12.children[2] = r121; r12.children[3] = r122; r12.children[4] = r123; r12.children[5] = r124;
	r0.parent = r;
	r1.parent = r;
	r01.parent = r0;
	r010.parent = r01;r011.parent = r01;
	r11.parent = r1;r12.parent = r1;
	r121.parent = r12;r122.parent = r12;r123.parent = r12;r124.parent = r12;
	return r
end


printname(node::PotreeConverter.CWNode) = println(PotreeConverter.name(node))
postorder(cmtree.root, printname)


traverse(cmtree.root, printname)

traverse(r, printname)
postorder(r, printname)
