using PotreeConverter
sources = [raw"D:\pointclouds\cava.las"]
outdir = "C:/Users/marte/Documents/GEOWEB/TEST/Potree"
pageName = "CAVA"

PotreeConverter.main(sources,outdir,pageName)



# PotreeConverter.exe  "D:\pointclouds\cava.las" -o C:/Users/marte/Documents/GEOWEB/TEST/Potree --output-format LAS -p TEST
# PotreeConverter.exe  "D:\pointclouds\Casaletto\casale.las" -o C:/Users/marte/Documents/GEOWEB/TEST/Potree --output-format LAS -p CASALE
# PotreeConverter.exe  "D:\pointclouds\Stairs.las" -o C:/Users/marte/Documents/GEOWEB/TEST/Potree --output-format LAS -p SCALE
