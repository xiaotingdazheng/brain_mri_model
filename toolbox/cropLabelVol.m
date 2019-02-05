function [mri2,cropping]=cropLabelVol(mri,margin)

if nargin<2
    margin=3;
end

V=mri.vol;

idx=find(V>0);

[I,J,K]=ind2sub(size(V),idx);
minI=min(I)-margin;
minJ=min(J)-margin;
minK=min(K)-margin;

maxI=max(I)+margin;
maxJ=max(J)+margin;
maxK=max(K)+margin;

minI=max(1,minI);
minJ=max(1,minJ);
minK=max(1,minK);
maxI=min(size(V,1),maxI);
maxJ=min(size(V,2),maxJ);
maxK=min(size(V,3),maxK);

cropping=[minI maxI minJ maxJ minK maxK];

mri2=[];
mri2.vol=V(minI:maxI,minJ:maxJ,minK:maxK);
v2r=mri.vox2ras0;
v2r(1:3,4)=v2r(1:3,4)+v2r(1:3,1:3)*[minJ-1; minI-1; minK-1];
mri2.vox2ras0=v2r;