import sys; sys.path.insert(0, __import__('os').path.dirname(__file__))
from scarf import *
S=2048
def icon(bg=True, inner=1.0):
    im=Image.new('RGBA',(S,S),NIGHT+(255,) if bg else (0,0,0,0))
    L=int(S*1.05*inner); H=int(S*0.2*inner)
    a=scarf(L,H,SUN).rotate(38,resample=Image.BICUBIC,expand=True)
    b=scarf(L,H,FLARE).rotate(-38,resample=Image.BICUBIC,expand=True)
    for sc in (a,b):
        # ombre douce
        sh=Image.new('RGBA',sc.size,(0,0,0,0)); sh.putalpha(sc.split()[3].point(lambda v:int(v*0.35)))
        from PIL import ImageFilter
        sh=sh.filter(ImageFilter.GaussianBlur(S*0.012))
        im.alpha_composite(sh,((S-sc.width)//2,(S-sc.height)//2+int(S*0.02)))
        im.alpha_composite(sc,((S-sc.width)//2,(S-sc.height)//2))
    return im
full=icon(inner=0.9)
full.resize((1024,1024),Image.LANCZOS).save('icon-1024.png')
# maskable : motif réduit dans la zone sûre (80 %)
mk=Image.new('RGBA',(S,S),NIGHT+(255,)); small=icon(bg=False,inner=0.72)
mk.alpha_composite(small)
mk.resize((1024,1024),Image.LANCZOS).save('icon-maskable-1024.png')
print('ok')
