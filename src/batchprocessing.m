ds = imageDatastore("Images");
nFiles = numel(ds.Files);
isReceipt = false(1,nFiles); %Precallocation of logical array

%Classify each image as either receipt or not
for k = 1:nFiles
   I = readimage(ds,k);
   isReceipt(k) = classifyImage(I);
end

%Select the results and display them 
receiptFiles = ds.Files(isReceipt);
montage(receiptFiles)
