using PotreeConverter

sources = [raw"D:\pointclouds\terreni\cava.las"] # path locale del file las da convertire
outdir = raw"C:\Users\marte\Documents\potreeDirectory\pointclouds" # path della cartella di destinazione
pageName = "ESEMPIO" # titolo del progetto
PotreeConverter.main(sources,outdir,pageName) # main
