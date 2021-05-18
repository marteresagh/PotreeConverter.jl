using PotreeConverter
sources = ["D:/pointclouds/cava.las"]
outdir = "C:/Users/marte/Documents/GEOWEB/TEST/Potree"
pageName = "CAVA"

PotreeConverter.main(sources,outdir,pageName)



# PotreeConverter.exe  "D:/pointclouds/cava.las" -o C:/Users/marte/Documents/GEOWEB/TEST/Potree --output-format LAS -p TEST --OVERWRITE
