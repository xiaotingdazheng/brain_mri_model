function [mri2,cropping]=cropLabelVol(mri,margin, label)

if nargin<2
    margin=3;
end
if nargin<3
    label=0;
end

V=mri.vol;

if label
    if isequal(label,'hippo')
        % crop around hiipo
        idx = find(V>20000 | V == 17 | V == 53);
    else
        % crop around a set of labels
        idx=[];
        for i=1:length(label)
            temp_idx=find(label(i));
            idx = vertcat(idx, temp_idx);
        end
    end
else
    % crop around all positive values
    idx = find(V>0.01);
end

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

% build new nitfy file
mri2=[];
mri2.vol=V(minI:maxI,minJ:maxJ,minK:maxK);
v2r=mri.vox2ras0;
v2r(1:3,4)=v2r(1:3,4)+v2r(1:3,1:3)*[minJ-1; minI-1; minK-1];
mri2.vox2ras0=v2r;
mri2.vox2ras1=v2r;
mri2.vox2ras=v2r;
mri2.xsize = mri.xsize; mri2.ysize = mri.ysize; mri2.zsize = mri.zsize;
mri2.volres = [mri.xsize mri.ysize mri.zsize];
mri2.tr = mri.tr; mri2.te = mri.te; mri2.ti = mri.ti;
mri2.volsize = size(mri2.vol);

end