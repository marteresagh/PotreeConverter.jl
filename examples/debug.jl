using PotreeConverter

aabb = PotreeConverter.pAABB([0.,0,0],[100,100.,100])
spacing = 0.01
grid = PotreeConverter.SparseGrid(aabb,spacing)
i,j,k = 1,1,1
key = (k << 40) | (j << 20) | i
this_cell = PotreeConverter.GridCell()
i,j,k = 1,2,1
key = (k << 40) | (j << 20) | i
this_cell = PotreeConverter.GridCell()
grid.map[key] = this_cell
PotreeConverter.GridCell(grid, PotreeConverter.GridIndex(2,2,1), this_cell)
