function isReceipt = classifyImage(I)
    % This function processes an image and
    % classifies the image as receipt or non-receipt
   
    

    % Processing (grayscaling + contrast adjustment) 
    gs = im2gray(I);
    gs = imadjust(gs);
    


    % Noise filter creation and application 
    mask = fspecial("average",3);
    gsSmooth = imfilter(gs,mask,"replicate");
    


    % Disk Structuring Element for background isolation and removal 
    SE = strel("disk",8);  
    Ibg = imclose(gsSmooth, SE);
    Ibgsub =  Ibg - gsSmooth;
    Ibw = ~imbinarize(Ibgsub);
    



    % Rectangle Structuring Element for stripe pattern emphasis
    SE = strel("rectangle", [3 25]); 
    stripes = imopen(Ibw, SE); 
     
    %montage({I, Ibw, stripes}); 



    % Calculation of row sums and plotting (receipt pattern) 
    signal = sum(stripes, 2); 
    minIndices = islocalmin(signal, "minprominence", 70, "prominenceWindow", 25); 
    nMin = nnz(minIndices); 
   % figure; plot(signal, "linewidth", 2); 

    disp(nMin); 


    % Classification: If the number of Minima bigger or equal to 9, the
    % image is a receipt (Manually chosen) 
    isReceipt  = nMin >=9;
    

end
