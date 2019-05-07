function mriCropped=applyCropping(mri,cropping)

% read mri
vol = mri.vol;
v2r=mri.vox2ras0;

% read cropping parameters
minI=cropping(1);
maxI=cropping(2);
minJ=cropping(3);
maxJ=cropping(4);
minK=cropping(5);
maxK=cropping(6);

% crop every channel of mri and concatenate them
volCropped = [];
for i=1:size(vol,4)
   volCropped = cat(4, volCropped, vol(minI:maxI,minJ:maxJ,minK:maxK,i)); 
end

% create new mri
mriCropped=[];
mriCropped.vol=volCropped;
v2r(1:3,4)=v2r(1:3,4)+v2r(1:3,1:3)*[minJ-1; minI-1; minK-1];
mriCropped.vox2ras0=v2r;
mriCropped.vox2ras1=v2r;
mriCropped.vox2ras=v2r;

end