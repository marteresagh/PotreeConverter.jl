using PotreeConverter
source = "D:/pointclouds/cava.las"
outdir = "C:/Users/marte/Documents/GEOWEB/TEST/Potree"
pageName = "CAVA"

PotreeConverter.main(source,outdir,pageName)


files = joinpath.("C:/Users/marte/Documents/GEOWEB/TEST/Potree/pointclouds/TEST/data/r",readdir("C:/Users/marte/Documents/GEOWEB/TEST/Potree/pointclouds/TEST/data/r"))
las = files[2:end]
using FileManager

io = open("potree_cpp.txt","w")
for file in las
    h,p = FileManager.LasIO.FileIO.load(file)
    write(io, "n_points:$(h.records_count),name: $(splitdir(file)[2])\n")
end
close(io)
pc = FileManager.las2pointcloud(files...)
h,p = FileManager.LasIO.load(las[1])
