"""Run in Blender background mode; audit original source topology before export."""
import bpy,bmesh,json,sys,math
from pathlib import Path
folder=Path(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else Path('assets/athletes')
report={}
for category in ['male','female']:
 bpy.ops.wm.open_mainfile(filepath=str((folder/'source'/(category+'.blend')).resolve()))
 meshes=[]
 for o in bpy.data.objects:
  if o.type!='MESH':continue
  bm=bmesh.new();bm.from_mesh(o.data);bm.normal_update()
  info={'name':o.name,'vertices':len(bm.verts),'triangles':sum(len(f.verts)-2 for f in bm.faces),'boundary_edges':sum(e.is_boundary for e in bm.edges),'nonmanifold_edges':sum(not e.is_manifold for e in bm.edges),'zero_length_edges':sum(e.calc_length()<1e-7 for e in bm.edges),'degenerate_faces':sum(f.calc_area()<1e-10 for f in bm.faces),'invalid_material_indices':sum(f.material_index<0 or f.material_index>=len(o.data.materials) for f in bm.faces),'invalid_normals':sum(not all(math.isfinite(c) for c in f.normal) or f.normal.length<.99 for f in bm.faces)}
  # Closed components must have outward winding, including thin face/clothing shells.
  unseen=set(bm.faces);volumes=[]
  while unseen:
   stack=[unseen.pop()];component=[]
   while stack:
    f=stack.pop();component.append(f)
    for e in f.edges:
     for neighbor in e.link_faces:
      if neighbor in unseen:unseen.remove(neighbor);stack.append(neighbor)
   volume=0
   for f in component:
    p=f.verts[0].co
    for i in range(1,len(f.verts)-1):volume+=p.dot(f.verts[i].co.cross(f.verts[i+1].co))/6
   volumes.append(volume)
  info['closed_components']=len(volumes);info['inward_components']=sum(v<-1e-12 for v in volumes)
  info['dark_forearm_faces']=sum(o.data.materials[f.material_index].name.startswith('Dark') and abs(f.calc_center_median().x)>.235 and .76<f.calc_center_median().z<1.1 for f in bm.faces)
  info['pass']=all(info[k]==0 for k in ['boundary_edges','nonmanifold_edges','zero_length_edges','degenerate_faces','invalid_material_indices','invalid_normals','inward_components','dark_forearm_faces'])
  meshes.append(info);bm.free()
 report[category]=meshes
(folder/'mesh_audit.json').write_text(json.dumps(report,indent=2)+'\n')
print('MESH_AUDIT',json.dumps(report))
if not all(m['pass'] for group in report.values() for m in group):raise RuntimeError('Source mesh audit failed; inspect mesh_audit.json')
