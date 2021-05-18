using PotreeConverter
using FileManager


raww = read(raw"C:\Users\marte\Documents\GEOWEB\TEST\Potree\pointclouds\TEST\data\r\r.hrc")
myraw = read(raw"C:\Users\marte\Documents\GEOWEB\TEST\Potree\CAVA\data\r\r.hrc")

treehrc = reshape(raww, (5, div(length(raww), 5)))






mytreehrc = reshape(myraw, (5, div(length(myraw), 5)))
