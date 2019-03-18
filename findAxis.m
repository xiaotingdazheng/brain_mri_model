function RefToFloAxisMap = findAxis(refmri, flomri)

refvox2ras = refmri.vox2ras0(1:3,1:3);
flovox2ras = flomri.vox2ras0(1:3,1:3);

refvox2ras = abs(normc(refvox2ras));
flovox2ras = abs(normc(flovox2ras));

[~, refRASidx] = max(refvox2ras, [], 2);
[~, floRASidx] = max(flovox2ras, [], 2);

RefToFloAxisMap = zeros(1,3,'single');
for i=1:3
    RefToFloAxisMap(i) = find(floRASidx == refRASidx(i));
end

end