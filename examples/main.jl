using PotreeConverter
source = "D:/pointclouds/cava.las"
outdir = "C:/Users/marte/Documents/GEOWEB/TEST/Potree"
pageName = "CAVA"

lasPoint = PotreeConverter.main(source,outdir,pageName)
