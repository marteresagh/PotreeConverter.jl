using PotreeConverter

sources = [raw"D:\pointclouds\cava.las"]
outdir = raw"C:\Users\marte\Documents\potreeDirectory\pointclouds"
pageName = "Julia"
PotreeConverter.main(sources,outdir,pageName)


## cmdline PotreeConverter originale
# PotreeConverter.exe  "D:\pointclouds\cava.las" -o C:/Users/marte/Documents/GEOWEB/TEST/Potree --output-format LAS -p TEST
# PotreeConverter.exe  "D:\pointclouds\Casaletto\casale.las" -o C:/Users/marte/Documents/GEOWEB/TEST/Potree --output-format LAS -p CASALE
# PotreeConverter.exe  "D:\pointclouds\nuvole\TFA16_nuvola UX5.las" -o C:/Users/marte/Documents/GEOWEB/TEST/Potree --output-format LAS -p TFA
