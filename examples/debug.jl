using PotreeConverter
using FileManager

myfile = raw"C:\Users\marte\Documents\GEOWEB\TEST\Potree\CAVA\data\r\r04.las"
potreefile = raw"C:\Users\marte\Documents\GEOWEB\TEST\Potree\pointclouds\TEST\data\r\r04.las"

my_aabb = FileManager.las2aabb(myfile)








potree_aabb = FileManager.las2aabb(potreefile)
