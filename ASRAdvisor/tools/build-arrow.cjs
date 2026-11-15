// Deterministic UI glyph asset. No font dependency, uncompressed 32-bit TGA.
const fs=require('node:fs'); const path=require('node:path');
const size=32, out=path.resolve(__dirname,'../media'); fs.mkdirSync(out,{recursive:true});
function inside(x,y,points){
 const [a,b,c]=points, cross=(p,q)=>(x-q[0])*(p[1]-q[1])-(p[0]-q[0])*(y-q[1]);
 const u=cross(a,b),v=cross(b,c),w=cross(c,a);return !(u<0||v<0||w<0)||!(u>0||v>0||w>0);
}
const outer=[[4,2],[30,16],[4,30]],inner=[[7,7],[25,16],[7,25]];
for(const direction of ['right','down']) {
 const bytes=Buffer.alloc(18+size*size*4);bytes[2]=2;bytes.writeUInt16LE(size,12);bytes.writeUInt16LE(size,14);bytes[16]=32;bytes[17]=0x28;
 for(let y=0;y<size;y++)for(let x=0;x<size;x++){
  const sum=[0,0,0,0];
  for(let sy=0;sy<4;sy++)for(let sx=0;sx<4;sx++){
   let px=x+(sx+.5)/4,py=y+(sy+.5)/4;if(direction==='down')[px,py]=[py,size-px];
   const fill=inside(px,py,inner),edge=inside(px,py,outer);
   const rgba=fill?[230,230,230,255]:edge?[18,18,18,245]:[0,0,0,0];
   for(let i=0;i<4;i++)sum[i]+=rgba[i]/16;
  }
  const i=18+(y*size+x)*4;bytes[i]=Math.round(sum[2]);bytes[i+1]=Math.round(sum[1]);bytes[i+2]=Math.round(sum[0]);bytes[i+3]=Math.round(sum[3]);
 }
 fs.writeFileSync(path.join(out,'arrow-'+direction+'.tga'),bytes);
}
console.log('Generated 32×32 arrow textures');
