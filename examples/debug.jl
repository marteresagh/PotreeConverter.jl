using PotreeConverter
using Common
using FileManager
# dato un potree e partendo dalle foglie devo continuare a costruire nodi se questi hanno più di un piano

potree = raw"C:\Users\marte\Documents\Julia_package\UTILS\potreeoriginale\MURI"
PotreeConverter.expand(potree, PotreeConverter.split_leaf)


cmtree = PotreeConverter.comaptree_generator(potree)
#
# # ############################
trie = FileManager.potree2trie(potree)
leaf_files = FileManager.get_leaf(trie)
