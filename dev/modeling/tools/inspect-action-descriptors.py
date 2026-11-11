#!/usr/bin/env python3
"""Read one qualified arm64 Mach-O/dSYM shape; never load or execute the module."""
import hashlib,json,re,struct,subprocess
from pathlib import Path

def inspect(root, cache):
    base=root/'../gerbil-gambit-bootstrap-audit/build/lib/std/db'
    obj=base/'sqlite~0.o1'; debug=base/'sqlite~0.o1.dSYM/Contents/Resources/DWARF/sqlite~0.o1'
    def readtool(name,args):
        p=subprocess.run(args,cwd=root,capture_output=True,text=True,timeout=30)
        (cache/(name+'.stdout')).write_text(p.stdout);(cache/(name+'.stderr')).write_text(p.stderr)
        (cache/(name+'.command.json')).write_text(json.dumps(args))
        assert p.returncode==0,(name,p.stderr)
        return p.stdout
    uuids=[re.search(r'UUID: ([A-F0-9-]+) \(arm64\)',readtool('descriptor-uuid-'+name,['/usr/bin/dwarfdump','--uuid',str(p)]))[1] for name,p in [('object',obj),('debug',debug)]]
    assert uuids[0]==uuids[1]
    dwarf=readtool('descriptor-dwarf',['/usr/bin/dwarfdump','--debug-info',str(debug)])
    b=obj.read_bytes();header=struct.unpack_from('<8I',b);assert header[0]==0xfeedfacf and header[1]==0x100000c
    pos=32;segments=[];fix=None;symtab=None
    for _ in range(header[4]):
        cmd,size=struct.unpack_from('<II',b,pos)
        if cmd==0x19:
            _,_,name,vm,vs,fo,fs,_,_,ns,_=struct.unpack_from('<II16sQQQQIIII',b,pos)
            segments.append(dict(name=name.rstrip(b'\0').decode(),vm=vm,size=vs,offset=fo,fileSize=fs))
        if cmd==0x80000034:fix=struct.unpack_from('<II',b,pos+8)
        if cmd==2:symtab=struct.unpack_from('<IIII',b,pos+8)
        pos+=size
    def offset(addr,count=8):
        valid=[s['offset']+addr-s['vm'] for s in segments if s['vm']<=addr and addr+count<=s['vm']+s['fileSize']]
        assert len(valid)==1,(addr,count)
        return valid[0]
    symbols={};so,nsy,stro,strsz=symtab
    for i in range(nsy):
        nameidx,typ,sect,desc,value=struct.unpack_from('<IBBHQ',b,so+i*16)
        if typ & 0xe0:continue
        end=b.index(b'\0',stro+nameidx,stro+strsz)
        symbols[b[stro+nameidx:end].decode()]=value
    lbl=symbols['____lbltbl'];hlbl=symbols['____hlbltbl.0']
    assert 'DW_AT_byte_size\t(0x20)' in dwarf and '___label_struct[429]' in dwarf and 'void *[430]' in dwarf
    for field,off in [('host_label',0),('host',8),('header',16),('entry_or_descr',24)]:
        block=dwarf.split('DW_AT_name\t("'+field+'")',1)[1].split('DW_TAG_',1)[0]
        assert f'DW_AT_data_member_location\t(0x{off:02x})' in block
    for name,addr in [('___lbltbl',lbl),('___hlbltbl',hlbl)]:
        block=dwarf.split('DW_AT_name\t("'+name+'")',1)[1].split('DW_TAG_',1)[0]
        assert f'DW_OP_addr 0x{addr:x}' in block
    ver,starts,*_=struct.unpack_from('<7I',b,fix[0]);assert ver==0
    si=fix[0]+starts;nseg=struct.unpack_from('<I',b,si)[0];offs=struct.unpack_from('<'+'I'*nseg,b,si+4)
    rebases={};formats=[]
    for index,x in enumerate(offs):
        if not x:continue
        size,page,fmt,segOff,maxp,np=struct.unpack_from('<IHHQIH',b,si+x);assert fmt==6
        formats.append(fmt);ps=struct.unpack_from('<'+'H'*np,b,si+x+22)
        for pn,first in enumerate(ps):
            if first==0xffff:continue
            assert not first&0x8000 # unsupported multi-start must fail closed
            addr=segOff+pn*page+first;seen=set()
            while True:
                assert addr not in seen;seen.add(addr)
                raw=struct.unpack_from('<Q',b,offset(addr))[0]
                assert not(raw>>63) and not((raw>>36)&0xff) and not((raw>>44)&0x7f)
                rebases[addr]=raw&((1<<36)-1)
                nxt=(raw>>51)&0xfff
                if not nxt:break
                addr+=4*nxt
    labels=[]
    for block in dwarf.split('DW_TAG_label')[1:]:
        n=re.search(r'DW_AT_name\s+\("(___L[0-3]_std_2f_db_2f_sqlite_23_____sqlite_2d_statement_2d_close)"\)',block)
        if not n:continue
        addr=int(re.search(r'DW_AT_low_pc\s+\((0x[0-9a-f]+)\)',block)[1],16)
        hits=[i for i in range(429) if rebases.get(hlbl+8*i)==addr];assert len(hits)==1
        i=hits[0];words=struct.unpack_from('<4Q',b,offset(lbl+32*i,32))
        row=dict(label=n[1],address=addr,index=i,words=[hex(v) for v in words])
        if n[1].startswith('___L0_'):assert words[3]==0
        else:
            assert words[2]==0x7e # retained return-object tag, cross-check header/source below
            d=words[3];kind=d&3;assert kind in (1,2)
            row.update(kind='RETN' if kind==1 else 'RETI',sizeField=(d>>2)&31,link=(d>>7)&31,gcmap=d>>12,
                markedBitIndices=[k for k in range(32) if (d>>12)&(1<<k)],machineDeadRegisterMask=None)
        labels.append(row)
    assert [r['index'] for r in labels]==[157,158,159,160]
    assert [(r['kind'],r['sizeField'],r['link'],r['gcmap']) for r in labels[1:]]==[('RETI',8,0,0x3f03),('RETN',5,0,3),('RETN',5,0,3)]
    result=dict(uuid=uuids[0],labelTable=hex(lbl),hostTable=hex(hlbl),labelStride=32,pointerFormats=formats,
        descriptors=labels,returnDescriptorsRecovered=3,deadRegisterMasksQualified=0,
        originalGeneration='unresolved',restoreClosure='unresolved',runtimeAdmitted=False,
        objectSha256=hashlib.sha256(b).hexdigest())
    (cache/'descriptor-recovery.json').write_text(json.dumps(result,indent=2)+'\n')
    return result
