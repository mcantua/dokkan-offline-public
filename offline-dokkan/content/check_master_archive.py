"""New bounded archive extraction cases, using both supplied master ZIPs read-only.
Usage: python3 check_master_archive.py /path/eclipse-db.zip /path/sparking-db.zip
No game apps, archives or extracted database bytes are retained by this check.
"""
import argparse,ctypes,hashlib,io,os,pathlib,sqlite3,struct,subprocess,tempfile,warnings,zipfile
ROOT=pathlib.Path(__file__).resolve().parent
class Result(ctypes.Structure):
 _fields_=[('bytes',ctypes.c_uint64),('crc32',ctypes.c_uint32),('entry',ctypes.c_char*64)]
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('eclipse_zip',type=pathlib.Path);parser.add_argument('sparking_zip',type=pathlib.Path);args=parser.parse_args()
def sha_file(path):
 h=hashlib.sha256()
 with open(path,'rb') as f:
  for chunk in iter(lambda:f.read(65536),b''):h.update(chunk)
 return h.hexdigest()
def archive(entries,method=zipfile.ZIP_DEFLATED,descriptor=False):
 class Unseekable(io.BytesIO):
  def seekable(self):return False
  def seek(self,*a):raise io.UnsupportedOperation()
 data=Unseekable() if descriptor else io.BytesIO()
 with warnings.catch_warnings(),zipfile.ZipFile(data,'w',compression=method) as z:
  warnings.simplefilter('ignore',UserWarning)
  for name,body in entries:z.writestr(name,body)
 return data.getvalue()
with tempfile.TemporaryDirectory(prefix='od-master-archive-') as directory:
 tmp=pathlib.Path(directory);so=tmp/'master_archive.so'
 subprocess.run(['cc','-std=c11','-Wall','-Wextra','-Werror','-fPIC','-shared',str(ROOT/'master_archive.c'),'-lz','-o',str(so)],check=True)
 lib=ctypes.CDLL(str(so));extract=lib.od_master_archive_extract;extract.argtypes=[ctypes.c_int,ctypes.c_int,ctypes.c_char_p,ctypes.POINTER(Result),ctypes.POINTER(ctypes.c_char_p)];extract.restype=ctypes.c_int
 def call(source,game='eclipse',expect=True):
  output=tmp/'fresh.sqlite';output.unlink(missing_ok=True);result=Result();error=ctypes.c_char_p()
  with open(source,'rb') as f,open(output,'xb+') as out:
   f.seek(7);offset=f.tell();rc=extract(f.fileno(),out.fileno(),game.encode(),ctypes.byref(result),ctypes.byref(error));assert f.tell()==offset,'source offset changed';assert out.tell()==0,'output not rewound'
   if expect:assert rc==0,(error.value,source)
   else:assert rc==-1 and out.seek(0,2)==0 and result.bytes==0,(error.value,rc,result.bytes)
  return output,result,error.value
 payload=None
 for game,source,allowed in [('eclipse',args.eclipse_zip,{'reference.db','assets/reference.db'}),('sparking',args.sparking_zip,{'sparking-reference.db','assets/sparking-reference.db'})]:
  before=sha_file(source)
  with zipfile.ZipFile(source) as z:
   names=[n for n in z.namelist() if n in allowed];assert len(names)==1;entry=z.getinfo(names[0]);expected=hashlib.sha256()
   with z.open(entry) as f:
    for chunk in iter(lambda:f.read(65536),b''):expected.update(chunk)
   if game=='eclipse':payload=z.read(entry)
  output,result,_=call(source,game);assert result.bytes==entry.file_size and result.crc32==entry.CRC and result.entry.decode()==entry.filename and sha_file(output)==expected.hexdigest() and sha_file(source)==before
  with sqlite3.connect('file:'+str(output)+'?mode=ro',uri=True) as db:assert db.execute('PRAGMA quick_check').fetchone()[0]=='ok' and db.execute('SELECT count(*) FROM cards').fetchone()[0]>1000
  print('PASS supplied '+game+' ZIP extracts identical SHA/length/CRC, actual SQLite master, unchanged archive/offset',flush=True)
 # Both supported compression forms and APK-like unrelated members. A descriptor
 # ZIP exercises forward-only ZIP writers rather than just Python's seekable ZIPs.
 small=payload[:512];stored=archive([('assets/reference.db',small),('classes.dex',b'UNRELATED')],zipfile.ZIP_STORED);streamed=archive([('reference.db',small)],descriptor=True)
 for label,data in [('stored APK layout',stored),('raw-deflate data descriptor',streamed)]:
  source=tmp/'shape.zip';source.write_bytes(data);output,_,_=call(source);assert output.read_bytes()==small
  print('PASS '+label+' exact allowlist extraction',flush=True)
 cases={
  'ambiguous two allowed DB names':archive([('reference.db',small),('assets/reference.db',small)]),
  'duplicate unrelated archive name':archive([('reference.db',small),('other',b'1'),('other',b'2')]),
  'wrong selected game':archive([('assets/sparking-reference.db',small)]),
  'traversal alias is never selected':archive([('../reference.db',small)]),
 }
 # Corruption after central preflight must clear already streamed output.
 corrupted=bytearray(stored);data_at=30+struct.unpack_from('<H',corrupted,26)[0]+struct.unpack_from('<H',corrupted,28)[0];corrupted[data_at+100]^=1;cases['bad CRC after output streaming']=corrupted
 for label,field,value,size in [('encrypted entry',8,1,2),('ZIP64 sentinel',24,0xffffffff,4),('oversized output',24,0x80000001,4)]:
  data=bytearray(stored);central=data.index(b'PK\x01\x02');struct.pack_into('<H' if size==2 else '<I',data,central+field,value);cases[label]=data
 # Set exactly matching local+central sizes while leaving deflate bytes trailing
 # inside the advertised payload; stream-end must consume every compressed byte.
 data=bytearray(archive([('reference.db',small)]));central=data.index(b'PK\x01\x02');compressed=struct.unpack_from('<I',data,central+20)[0];data_at=30+struct.unpack_from('<H',data,26)[0];data[data_at+compressed:data_at+compressed]=b'X';central+=1;struct.pack_into('<I',data,18,compressed+1);struct.pack_into('<I',data,central+20,compressed+1);end=data.index(b'PK\x05\x06');struct.pack_into('<I',data,end+16,central);cases['trailing compressed payload']=data
 for label,data in cases.items():
  source=tmp/'invalid.zip';source.write_bytes(data);before=sha_file(source);call(source,expect=False);assert sha_file(source)==before
  print('PASS '+label+' rejected, no output retained or source modification',flush=True)
 source=tmp/'valid.zip';source.write_bytes(stored);output=tmp/'existing.sqlite';output.write_bytes(b'KEEP');result=Result();error=ctypes.c_char_p()
 with open(source,'rb') as f,open(output,'rb+') as out:assert extract(f.fileno(),out.fileno(),b'eclipse',ctypes.byref(result),ctypes.byref(error))==-1
 assert output.read_bytes()==b'KEEP';print('PASS nonfresh destination rejected without truncating existing data',flush=True)
