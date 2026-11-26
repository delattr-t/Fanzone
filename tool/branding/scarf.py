import math
from PIL import Image, ImageDraw, ImageFont

NIGHT=(43,26,18); CREAM=(255,243,224); FLARE=(226,70,43); SUN=(255,180,32); WOOL=(246,237,224)
import os
FONT=os.environ.get('BRICO_TTF', 'BricolageGrotesque.ttf')

def font(size, wght=800):
    f=ImageFont.truetype(FONT, size)
    f.set_variation_by_axes([min(96,max(12,size)), wght, 100])
    return f
def scarf(width, h, color, label=None, fringe=True, stripe=CREAM, ss=1):
    """Réplique Python de _ScarfPainter (widgets/scarf.dart)."""
    W, H = int(width), int(h)
    img=Image.new('RGBA',(W,H),(0,0,0,0)); d=ImageDraw.Draw(img)
    s=max(2.5,min(7.0*ss*1.0, H/6)) if ss==1 else H/6
    s=H/6
    f=H*0.34 if fringe else 0
    body=(f,0,W-f,H)
    dark=tuple(int(c*0.92) for c in color)
    if fringe:
        n=max(3,int(H/(s*1.25))); step=(H-s)/(n-1)
        for i in range(n):
            y=s/2+i*step; l=f*(0.78+0.22*((i*7)%5)/4)
            d.line([(f,y),(f-l,y)],fill=dark,width=max(2,int(s*0.5)))
            d.line([(W-f,y),(W-f+l,y)],fill=dark,width=max(2,int(s*0.5)))
    bodyimg=Image.new('RGBA',(int(W-2*f),H),color+(255,)); bd=ImageDraw.Draw(bodyimg)
    bw=bodyimg.width
    band1,band2,gap,inset=H*0.16,H*0.08,H*0.12,H*0.22
    for x0,w in [(inset,band1),(inset+band1+gap,band2),(bw-inset-band1,band1),(bw-inset-band1-gap-band2,band2)]:
        bd.rectangle([x0,0,x0+w,H],fill=stripe)
    if label:
        size=int(H*0.36)
        ft=font(size)
        txt=label.upper()
        sp=H*0.05
        widths=[bd.textlength(c,font=ft) for c in txt]
        tw=sum(widths)+sp*(len(txt)-1)
        x=bw/2-tw/2; y=H/2
        for c,wc in zip(txt,widths):
            bd.text((x,y),c,font=ft,fill=stripe,anchor='lm'); x+=wc+sp
    # mailles
    ov=Image.new('RGBA',bodyimg.size,(0,0,0,0)); od=ImageDraw.Draw(ov)
    y=s*0.25; row=0
    while y<H:
        shift=0 if row%2==0 else s*0.5
        x=-s+shift
        while x<bw+s:
            od.line([(x+s*0.1,y),(x+s*0.5,y+s*0.6),(x+s*0.9,y)],fill=(0,0,0,36),width=max(1,int(s*0.2)),joint='curve')
            od.line([(x+s*0.18,y-s*0.12),(x+s*0.5,y+s*0.36)],fill=(255,255,255,24),width=max(1,int(s*0.16)))
            x+=s
        y+=s*0.92; row+=1
    bodyimg=Image.alpha_composite(bodyimg,ov)
    mask=Image.new('L',bodyimg.size,0); ImageDraw.Draw(mask).rounded_rectangle([0,0,bodyimg.width-1,H-1],radius=min(6*H/44,H*0.14),fill=255)
    img.paste(bodyimg,(int(f),0),mask)
    return img
