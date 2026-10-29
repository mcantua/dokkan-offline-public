import struct,sys,zipfile
def parse(b):
    # minimal binary XML decoder (string pool + start tags with attributes)
    pos=8; strings=[]; out=[]; depth=0; resmap=[]
    while pos<len(b):
        t,hs,sz=struct.unpack_from('<HHI',b,pos)
        if t==0x0001:
            n,styles,flags,so,sto=struct.unpack_from('<IIIII',b,pos+8)
            utf8=flags&0x100; offs=struct.unpack_from('<%dI'%n,b,pos+28)
            base=pos+so
            for o in offs:
                p=base+o
                if utf8:
                    l=b[p]; p+= 2 if l&0x80 else 1
                    l2=b[p]; 
                    if l2&0x80: l2=((l2&0x7f)<<8)|b[p+1]; p+=2
                    else: p+=1
                    strings.append(b[p:p+l2].decode('utf8','replace'))
                else:
                    l=struct.unpack_from('<H',b,p)[0]; p+=2
                    if l&0x8000: l=((l&0x7fff)<<16)|struct.unpack_from('<H',b,p)[0]; p+=2
                    strings.append(b[p:p+2*l].decode('utf16','replace'))
        elif t==0x0102:
            ns,name,ast,asz,ac=struct.unpack_from('<IIHHH',b,pos+16)
            attrs=[]
            for i in range(ac):
                a=pos+16+ast+i*asz
                ans,aname,araw,vs,_,vt,vd=struct.unpack_from('<IIIHBBI',b,a)
                v=strings[araw] if araw!=0xffffffff else ('@%08x'%vd if vt==1 else str(vd) if vt in (16,17) else ('true' if vd else 'false') if vt==18 else hex(vd))
                attrs.append('%s=%r'%(strings[aname] if aname<len(strings) else aname,v))
            out.append('  '*depth+'<'+strings[name]+' '+' '.join(attrs)+'>'); depth+=1
        elif t==0x0103: depth-=1
        pos+=sz
    return out
z=zipfile.ZipFile(sys.argv[1]); print('\n'.join(parse(z.read('AndroidManifest.xml'))))
