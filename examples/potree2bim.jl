using PotreeConverter
using Common
using FileManager
using Detection
using Visualization

potree = raw"C:\Users\marte\Documents\Julia_package\UTILS\potreeoriginale\MURI"
FileManager.get_leaf(FileManager.potree2trie(potree))
collection = PotreeConverter.potree2bim(potree; LOD = -1)


out = Array{Common.Struct,1}()
for node in collection[1:1]
    V,cells = PotreeConverter.nuova_procedura(node)
    push!(out, Common.Struct([V,cells])) # triangles cells
end
out = Common.Struct( out )
V, FVs = Common.struct2lar(out)
