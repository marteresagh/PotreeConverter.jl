using PotreeConverter
using Common
using FileManager
using Detection
using Visualization

potree = raw"C:\Users\marte\Documents\Julia_package\UTILS\potreeoriginale\MURI"
collection = PotreeConverter.potree2bim(potree; LOD = -1)
