using PotreeConverter
using FileManager


raw = read(raw"C:\Users\marte\Documents\GEOWEB\TEST\Potree\CAVA\data\r\r.hrc")
treehrc = reshape(raw, (5, div(length(raw), 5)))

for i in 1:size(treehrc,2)
    children = Int(treehrc[1,i])
    @show children
    npoints = parse(Int, bitstring(UInt8(treehrc[5,i]))*bitstring(UInt8(treehrc[4,i]))*bitstring(UInt8(treehrc[3,i]))*bitstring(UInt8(treehrc[2,i])); base=2)
    @show npoints
    break
end
