"""Original Road to Gold review assets. Blender 4.3+, no add-ons/downloads.
Run: blender --background --python tools/athletes/generate_athletes.py -- <output dir>
Units are metres. Blender +Y front exports as Godot -Z front.
"""
import bpy, bmesh, math, sys, json
from pathlib import Path
from mathutils import Vector
OUT=Path(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else Path('assets/athletes')
OUT.mkdir(parents=True,exist_ok=True)

def material(name,color):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=.88
 return m

def mesh(name,verts,faces,mat):
 data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update();bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(data);bm.free();o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o);o.data.materials.append(mat)
 for p in data.polygons:p.use_smooth=True
 if name in ['Eye','Brow','Mouth','Nose']:
  solid=o.modifiers.new('Closed facial detail','SOLIDIFY');solid.thickness=.001;apply(o,solid)
 return o

def loft(name,rings,mat,segments=12):
 # (x,y,z, side radius, depth radius), aligned cross-sections along Z.
 v=[];f=[]
 for x,y,z,rx,ry in rings:
  for j in range(segments):
   a=math.tau*j/segments;v.append((x+rx*math.sin(a),y+ry*math.cos(a),z))
 for k in range(len(rings)-1):
  for j in range(segments):
   a=k*segments+j;b=k*segments+(j+1)%segments;f.append((a,b,b+segments,a+segments))
 f.append(tuple(reversed(range(segments))));f.append(tuple((len(rings)-1)*segments+j for j in range(segments)))
 return mesh(name,v,f,mat)

def oval(name,at,size,mat,segments=12,rings=6):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,radius=1,location=at);o=bpy.context.object;o.name=name;o.scale=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
 for p in o.data.polygons:p.use_smooth=True
 return o

def join(objects,name):
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();o=bpy.context.object;o.name=name;return o

def apply(o,modifier):
 bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=modifier.name)

def bone_weights(o,bones,head_only=False):
 groups={n:o.vertex_groups.new(name=n) for n,_,_ in bones}
 for vertex in o.data.vertices:
  p=o.matrix_world@vertex.co
  if head_only:weights=[('Head',1)]
  else:
   candidates=[]
   x,y,z=p;side='L' if x>0 else 'R';ax=abs(x)
   allowed=['Pelvis','Spine','Chest','Neck','Head']
   if ax>.19 and .72<z<1.46:allowed=[side+'Clavicle',side+'UpperArm',side+'Forearm',side+'Hand','Chest']
   elif z<1.02 and ax>.035:allowed=[side+'Thigh',side+'Calf',side+'Foot',side+'Toe','Pelvis']
   elif z>1.55:allowed=['Head']
   for name,a,b in bones:
    if name not in allowed:continue
    a=Vector(a);b=Vector(b);t=max(0,min(1,(p-a).dot(b-a)/max((b-a).length_squared,1e-8)));dist=(p-a-(b-a)*t).length
    candidates.append((name,1/(dist+.022)**4))
   candidates.sort(key=lambda a:-a[1]);candidates=candidates[:3];total=sum(w for _,w in candidates);weights=[(n,w/total) for n,w in candidates]
  for name,w in weights:groups[name].add([vertex.index],w,'REPLACE')

def shapes(o):
 # All meshes have identical named shape channels, including head/hair translation.
 basis=o.shape_key_add(name='Basis')
 for name in ['Build','Shoulders','Legs']:
  key=o.shape_key_add(name=name);key.slider_min=-1;key.slider_max=2
  for i,v in enumerate(basis.data):
   x,y,z=v.co
   if name=='Build':
    factor=.26*max(0,min(1,(1.54-z)/.12));key.data[i].co=(x*(1+factor),y*(1+factor),z)
   elif name=='Shoulders':
    factor=.3*max(0,min(1,(z-.95)/.30))*max(0,min(1,(1.55-z)/.1));key.data[i].co=(x*(1+factor),y,z)
   else:key.data[i].co=(x,y,z+.92*.15 if z>=.92 else z*1.15)

def make(category):
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 skin=material('Skin',(0.53,.30,.17));kit=material('Kit',(.72,.43,.055));dark=material('Dark',(.018,.032,.045));hair=material('Hair',(.045,.024,.014));white=material('White',(.76,.73,.65));face=material('Face',(.043,.029,.028))
 female=category=='female';w=.89 if female else 1;hip=1.10 if female else 1
 body=[]
 body.append(loft('Trunk',[(0,0,z,rx*(hip if z<1.02 else w),ry) for z,rx,ry in [(.88,.135,.089),(.96,.146,.095),(1.04,.137,.086),(1.13,.150,.089),(1.23,.181,.101),(1.32,.202,.105),(1.39,.206,.091),(1.43,.07,.06)]],skin,16))
 body.append(loft('Neck',[(0,0,1.39,.071,.060),(0,0,1.46,.057,.052),(0,.006,1.55,.055,.054),(0,.006,1.58,.058,.060)],skin))
 head_object=loft('Head',[(0,cy,z,rx*(.95 if female else 1),ry) for z,rx,ry,cy in [(1.55,.060,.059,.006),(1.575,.083,.078,.002),(1.62,.107,.10,0),(1.67,.11,.103,-.004),(1.72,.107,.103,-.008),(1.765,.087,.084,-.013),(1.79,.05,.052,-.02),(1.803,.008,.009,-.023)]],skin,16)
 ears=[]
 for side in [-1,1]:
  body.append(loft('Leg',[(side*.087,0,z,rx,ry) for z,rx,ry in [(.11,.030,.035),(.23,.043,.046),(.35,.054,.059),(.46,.044,.049),(.51,.047,.050),(.66,.061,.067),(.79,.074,.080),(.94,.081,.085)]],skin))
  sx=side*w
  body.append(loft('Arm',[(sx*x,y,z,rx,ry) for x,y,z,rx,ry in [(.295,.018,.875,.025,.027),(.285,.015,.98,.037,.039),(.275,.012,1.045,.043,.043),(.267,.008,1.12,.037,.039),(.244,0,1.25,.051,.052),(.208,0,1.38,.062,.065)]],skin))
  body.append(oval('Deltoid',(sx*.202,0,1.355),(.068,.067,.09),skin))
  body.append(oval('Palm',(sx*.298,.020,.824),(.031,.025,.064),skin))
  body.append(oval('Thumb',(sx*.273,.037,.835),(.017,.018,.042),skin,8,4))

  ears.append(oval('Ear',(side*.108,-.002,1.66),(.022,.028,.035),skin,8,4))
 # Union and retopologize overlapping construction volumes into a connected skin.
 body=join(body,'AthleteBody');bpy.context.view_layer.objects.active=body
 remesh=body.modifiers.new('Connected anatomy','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.012;remesh.use_smooth_shade=True;apply(body,remesh)
 smooth=body.modifiers.new('Anatomical transitions','SMOOTH');smooth.factor=.65;smooth.iterations=4;apply(body,smooth)
 dec=body.modifiers.new('Low-poly topology','DECIMATE');dec.ratio=.12;apply(body,dec)
 # Separate fitted garment shells: no centroid-based material cuts on skin.
 body.data.materials.clear();body.data.materials.append(skin)
 for polygon in body.data.polygons:polygon.material_index=0;polygon.use_smooth=True
 objects=[body,head_object]+ears
 shirt=loft('AthleticTop',[(0,0,z,rx*w,ry) for z,rx,ry in [(1.005,.145,.101),(1.04,.143,.092),(1.13,.156,.095),(1.23,.187,.108),(1.32,.208,.112),(1.38,.212,.098),(1.415,.14,.081),(1.435,.074,.067)]],kit,16)
 # Real dipped neckline; keep it outside the chest, with a thin fabric shell.
 for j in range(16):
  a=math.tau*j/16;c=max(0,math.cos(a));v=shirt.data.vertices[7*16+j]
  v.co=(.074*w*math.sin(a),.067*math.cos(a)+.038*c**3,1.435-.04*c*c)
 bm=bmesh.new();bm.from_mesh(shirt.data);bmesh.ops.delete(bm,geom=[f for f in bm.faces if len(f.verts)>4],context='FACES_ONLY');bm.to_mesh(shirt.data);bm.free()
 solid=shirt.modifiers.new('Fabric edge thickness','SOLIDIFY');solid.thickness=.002;solid.offset=0;apply(shirt,solid);objects.append(shirt)
 # The rim follows the exact same U-shaped opening; no floating horizontal disc.
 v=[];f=[]
 for k in range(2):
  for j in range(16):
   a=math.tau*j/16;c=max(0,math.cos(a));v.append((.075*w*math.sin(a),.068*math.cos(a)+.038*c**3,1.435-.04*c*c+k*.006))
 for j in range(16):a=j;b=(j+1)%16;f.append((a,b,b+16,a+16))
 rim=mesh('NeckRim',v,f,white);solid=rim.modifiers.new('Closed rim','SOLIDIFY');solid.thickness=.001;apply(rim,solid);objects.append(rim)
 objects.append(loft('ShortWaist',[(0,0,.855,.175*hip,.121),(0,0,.95,.163*hip,.110),(0,0,1.012,.157*hip,.108)],dark,16))
 for side in [-1,1]:
  objects.append(loft('ShortLeg',[(side*.087,0,.765,.082,.090),(side*.087,0,.86,.094,.102),(side*.087,0,.94,.094,.100)],dark,12))

 for side in [-1,1]:
  # Almond eye planes, pupils, tapered brow, small nose and lip avoid oversized eyes.
  cx=side*.046;z=1.682;y=.095
  verts=[(cx-.021,y-.004,z),(cx-.011,y+.003,z+.008),(cx+.010,y+.003,z+.007),(cx+.021,y-.004,z),(cx+.010,y+.002,z-.006),(cx-.010,y+.002,z-.006)]
  objects.append(mesh('Eye',verts,[(0,1,2,3,4,5)],white))
  objects.append(oval('Pupil',(cx,y+.006,z),(.006,.003,.0065),face,8,4))
  objects.append(mesh('Brow',[(cx-.023,.096,1.705),(cx-.012,.102,1.709),(cx+.013,.100,1.708),(cx+.024,.094,1.703),(cx+.010,.100,1.704),(cx-.012,.100,1.705)],[(0,1,2,3,4,5)],hair))
  x=side*.087
  # Shaped shoe: heel-to-toe horizontal rings; low bevelled sole.
  v=[];f=[];rings=[(-.075,.035,.045),(-.03,.047,.055),(.055,.051,.045),(.13,.043,.032),(.165,.019,.018)]
  for cy,rx,rz in rings:
   for j in range(10):
    a=math.tau*j/10;v.append((x+rx*math.sin(a),cy,max(.022,.067+rz*math.cos(a))))
  for k in range(len(rings)-1):
   for j in range(10):a=k*10+j;b=k*10+(j+1)%10;f.append((a,a+10,b+10,b))
  f+=[tuple(reversed(range(10))),tuple(40+j for j in range(10))];objects.append(mesh('Shoe',v,f,dark))
  objects.append(oval('Sole',(x,.041,.027),(.052,.128,.015),white))
  objects.append(loft('Sock',[(x,0,.09,.039,.045),(x,0,.155,.040,.046)],white))
  for row in range(3):objects.append(oval('Lace',(x,.03+row*.018,.11-row*.004),(.031,.004,.003),kit,8,4))
 nose=[(-.015,.094,1.67),(.015,.094,1.67),(0,.121,1.645),(-.018,.102,1.634),(.018,.102,1.634),(0,.097,1.63)]
 objects.append(mesh('Nose',nose,[(0,1,2),(0,2,3),(1,4,2),(2,4,5,3)],skin))
 objects.append(mesh('Mouth',[(-.025,.093,1.608),(0,.102,1.609),(.025,.093,1.607),(0,.102,1.605)],[(0,1,2,3)],face))
 # Original compact swept hair cap, curls and layered ponytail. No textures.
 def scalp():
  v=[];f=[];n=16;levels=5
  for k in range(levels):
   t=k/(levels-1);r=max(.008,math.cos(t*math.pi/2)*.115)
   for j in range(n):
    a=math.tau*j/n;z=1.65+.085*max(0,math.cos(a));z=z+(1.819-z)*math.sin(t*math.pi/2)
    v.append((r*math.sin(a),-.012+r*math.cos(a),z))
  for k in range(levels-1):
   for j in range(n):a=k*n+j;b=k*n+(j+1)%n;f.append((a,b,b+n,a+n))
  f.append(tuple(reversed(range(n))));f.append(tuple((levels-1)*n+j for j in range(n)))
  return mesh('Scalp',v,f,hair)
 styles=[]
 for style in ['Cropped','Curls','Ponytail']:
  pieces=[scalp()]
  if style=='Cropped':
   for j in range(5):
    lock=oval('SweptLock',(-.060+j*.028,.018,1.79+.004*j),(.029,.072,.039),hair,12,6)
    lock.rotation_euler.y=-.25;pieces.append(lock)
  elif style=='Curls':
   for j in range(14):
    a=j*2.39996;r=.075*math.sqrt((j+.5)/14);pieces.append(oval('Curl',(r*math.sin(a),r*math.cos(a)-.01,1.80+(.03 if j%3==0 else 0)),(.036,.038,.033),hair,8,4))
  else:
   for j in range(3):pieces.append(loft('Tail',[(.017*(j-1),-.099,1.74,.035,.034),(.018*(j-1),-.133,1.64,.031,.029),(.012*(j-1),-.145,1.53,.023,.026),(.008*(j-1),-.12,1.43,.006,.01)],hair,8))
  hair_mesh=join(pieces,'Hair_'+style)
  remesh=hair_mesh.modifiers.new('Clean connected hair','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.007;remesh.use_smooth_shade=True;apply(hair_mesh,remesh)
  smooth=hair_mesh.modifiers.new('Hair transitions','SMOOTH');smooth.factor=.4;smooth.iterations=2;apply(hair_mesh,smooth)
  dec=hair_mesh.modifiers.new('Low-poly hair','DECIMATE');dec.ratio=.08;apply(hair_mesh,dec)
  styles.append(hair_mesh)
 objects.extend(styles)
 for obj in objects:
  if obj.name.startswith(('Head','Ear','Eye','Pupil','Brow','Nose','Mouth','Hair_')):obj.location.z-=.055
 # Humanoid rest skeleton. Future sports clips can use these real weighted joints.
 bones=[('Root',(0,0,0),(0,0,.15)),('Pelvis',(0,0,.88),(0,0,1.02)),('Spine',(0,0,1.02),(0,0,1.19)),('Chest',(0,0,1.19),(0,0,1.40)),('Neck',(0,0,1.40),(0,0,1.495)),('Head',(0,0,1.495),(0,0,1.735))]
 parents={'Pelvis':'Root','Spine':'Pelvis','Chest':'Spine','Neck':'Chest','Head':'Neck'}
 for side,sgn in [('L',1),('R',-1)]:
  chain=[('Clavicle',(.025,0,1.39),(.202*w,0,1.36),'Chest'),('UpperArm',(.202*w,0,1.36),(.267*w,.008,1.12),side+'Clavicle'),('Forearm',(.267*w,.008,1.12),(.295*w,.018,.88),side+'UpperArm'),('Hand',(.295*w,.018,.88),(.298*w,.02,.77),side+'Forearm'),('Thigh',(.087,0,.93),(.087,0,.48),'Pelvis'),('Calf',(.087,0,.48),(.087,0,.12),side+'Thigh'),('Foot',(.087,0,.12),(.087,.10,.05),side+'Calf'),('Toe',(.087,.10,.05),(.087,.165,.04),side+'Foot')]
  for name,a,b,parent in chain:
   bones.append((side+name,(a[0]*sgn,a[1],a[2]),(b[0]*sgn,b[1],b[2])));parents[side+name]=parent
 arm=bpy.data.armatures.new('AthleteHumanoid');rig=bpy.data.objects.new('AthleteRig',arm);bpy.context.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
 for name,a,b in bones:
  bone=arm.edit_bones.new(name);bone.head=a;bone.tail=b
  if name in parents:bone.parent=arm.edit_bones[parents[name]]
 bpy.ops.object.mode_set(mode='OBJECT')
 # Collapse details by material/role; hairstyles stay independently selectable.
 details=[o for o in objects if o!=body and not o.name.startswith('Hair_')]
 body=join([body]+details,'AthleteMesh');objects=[body]+styles
 for o in objects:
  # Put all coordinates in the same unit space before morph/weight generation.
  bpy.context.view_layer.objects.active=o;bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
  bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bmesh.ops.triangulate(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free()
  shapes(o);bone_weights(o,bones,head_only=o in styles)
  modifier=o.modifiers.new('Humanoid skin','ARMATURE');modifier.object=rig;o.parent=rig
 bpy.ops.object.select_all(action='SELECT')
 source=OUT/'source';source.mkdir(exist_ok=True);(source/'.gdignore').touch();bpy.ops.wm.save_as_mainfile(filepath=str(source/(category+'.blend')))
 bpy.ops.export_scene.gltf(filepath=str(OUT/(category+'.glb')),export_format='GLB',use_selection=False,export_yup=True,export_skins=True,export_morph=True,export_animations=False,export_materials='EXPORT',export_apply=False)
 return {'category':category,'bones':len(bones),'body_triangles':sum(len(p.vertices)-2 for p in body.data.polygons),'total_triangles_all_hair':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in objects)}

stats=[make(c) for c in ['male','female']]
(OUT/'generation.json').write_text(json.dumps({'blender':bpy.app.version_string,'original_assets':True,'models':stats},indent=2)+'\n')
print('ATHLETE_ASSET_STATS',json.dumps(stats))
