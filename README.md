# MATLAB-image-processing (Receipt Classification) 
The implementation of the image processing algorithm for receipt classification taught on the "Image Processing Onramp" course, featuring contrast adjustment, noise filtering, morphological operations, binary masking, and local extrema analysis for sound distinction between receipt and non-receipt images. 

The algorithm workflow is as follows: 
Input Image
→ Grayscale Conversion
→ Contrast Adjustment
→ Noise Reduction
→ Background Estimation
→ Background Subtraction
→ Image Binarization
→ Horizontal Projection Profile
→ Local Minima Detection
→ Receipt Classification

I will explain the classifyImage.m script: 

```matlab
function isReceipt = classifyImage(I)
    % instructions to be detailed 
end
```

This creates the classification function, which takes an input image I, and returns a logical value stored in isReceipt; If it returns logical 1, it's a receipt value, if 0, it's not. 

```matlab
gs = im2gray(I);
gs = imadjust(gs);
```

The  im2gray()  function takes an RGB image I, and transforms it into a grayscale image. This is more computationally efficient as a grayscale image is third the size of an RGB image.  

The imadjust() function takes a grayscale image, analyzes it's intensity histogram, and adjusts the contrast of the image automatically to make it visually clearer. The result is stored in gs.   

```matlab
mask = fspecial("average",3);
gsSmooth = imfilter(gs,mask,"replicate");
```
The fspecial() function creates a mask/filter/window and stores it in mask variable. The window will slide across each pixel of the screen and change it's intensity value based on the neighboring pixels. "average" indicates that the new value will be the mean of the neighboring pixel intensity values. "3" indicates the size of the sliding window, it will be a 3 by 3 matrix. (3 pixels in height, 3 pixels in width) 

The imfilter() function takes the created filter or mask and applies it to gs. This removes noise from the picture. The "replicate" tag ensures that there will be no dark borders in the output image. The result is stored in gsSmooth.  

```matlab
SE = strel("disk",8);  
Ibg = imclose(gsSmooth, SE);
Ibgsub =  Ibg - gsSmooth;
Ibw = ~imbinarize(Ibgsub);
```

The strel() function creates a structuring element, a sliding window similar to the previous filter, but which will help us apply various morphological operations on the image (Like Dilation, Erosion, Opening, Closing..). "Disk" indicates that the sliding window is a disk, and it's radius is 8 pixels.  Result is stored in SE. 

The imclose() function applies the closing operation. This operation emphasizes and connects the bright parts of the image thereby removing the black text from the receipt images and leaving only the background. The background of the receipt images is stored in Ibg.  

We perform a subtraction to remove the background from the original image. We subtracted gsSmooth from Ibg, instead of Ibg from gsSmooth because Ibg's pixels will have higher intensity values (due to the closing operation) and therefore will NOT result in any negative numbers. This is important because images in MATLAB are stored using uint8 data type. 

The result of the subtraction is Ibgsub, and because the pixel intensity values in Ibg are either equal or higher than the pixel intensities of gsSmooth, there will be perfect subtractions, resulting in a lot of 0's, and subtractions that will make the text appear lighter. This is why the image colors have been reversed.  To correct this, we will first of all create a binary image using the imbinarize() function, and we will invert it using the "~" operator, which is the logical NOT operator.  Ibw then is a receipt image with a clean background.  

```matlab
SE = strel("rectangle", [3 25]); 
stripes = imopen(Ibw, SE);
```

In order to reinforce the black text, and extract a characteristic pattern that only characterizes receipt images and not other types, we will need to create a structuring element again. 

Strel("rectangle", [3 25]) creates a structuring element that is rectangular in shape, with a height of 3 pixels, and a width of 25 pixels. The reason why it is rectangular is because when trying to emphasize an object in an image, the structuring element should mimic it's shape (at least in approximation). Because the object we want to emphasize is a text, a rectangular structuring is the closest possible shape for it. The height of 3 pixels is important because we don't want to connect texts with each other when we apply the opening operation, instead we want to leave an alternation between black and white stripes.

the imopen() function performs an opening operation. It emphasizes and connects the dark parts of an image. Like mentioned earlier if we had chosen a value bigger than 3 pixels, the black stripes will connect, forming a single black blob. But when it is 3 pixels, we have an alternation between black and white stripes. This pattern is the one that will separate receipt images from non-receipt images.  The result is stored in stripes.  

```matlab
signal = sum(stripes, 2); 
minIndices = islocalmin(signal, "minprominence", 70, "prominenceWindow", 25); 
nMin = nnz(minIndices);
```

In order to visualize the stripes we create a signal vector. This is done by summing the pixel values at every row of the image. The "2" indicates that the summing is done horizontally, and this will produce a column vector.  We can plot this using plot(signal): The peaks represent rows that only have white pixels and therefore no text, and the valleys will represent rows where text is present. 

In order to quantify this pattern  we will use the islocalmin() function which will scan the signal vector, and will switch the values with either 1 or 0. It will switch it with 1 if the value is a minima, and with 0 if it is not. What is considered as a minima or not depends on the following tags: 

"minprominence": This is the threshold by which we consider a point to be a minimum or not. The higher it is the more strict we are about naming a point a "minimum" and therefore the number of minima will decrease.  70 was found manually and it seemed to work most of the time (but not all of the time))
"prominencewindow": This is the window by which we compare how deep a minima is relative to others. The lower it is, the higher the number of minima.  

The results are stored in the logical vector minIndices which the same length as signal vector.  
In order to determine the number of minima, we use the nnz() function which returns the number of non-zero elements in a vector.  

```matlab
isReceipt  = nMin >=9
```

And finally the factor that will determine whether an image is a receipt or not is the condition nMin >=9. If it is bigger, it will be a receipt. If not, it will be not. This was also manually determined. 
One can play with a combination of "minprominence" "prominencewindow" and "nMin>=?" to find the best possible combination with no errors.  


So if I were to apply this in an example I would do the following: 

```matlab
I = imread("Image_001.png"); 
classifyImage(I) 
```

However, what if we want to treat thousands of images at once?  Now we will treat the batchprocess.m script.  

```matlab
ds = imageDatastore("Images");
nFiles = numel(ds.Files);
isReceipt = false(1,nFiles);
```

The imageDatastore() function creates a data store data type in MATLAB which plays the role as a reference to a source of data without having to import thousands of images into the workspace which is not efficient on the memory. "Images" is the folder. You set the path.  

The numel() function determins how many elements are in an array or cell. We are seeing how many elements or images are there in the folder. ds.Files is a cell array containing the image references.  

We preallocate isReceipt.  

```matlab
for k = 1:nFiles
   I = readimage(ds,k);
   isReceipt(k) = classifyImage(I);
end
```

This is a for loop that will go over every image in the folder, read it using readimage(dataSource, number of image) function, and stopre the result in the logical array isReceipt() using the classifyImage() function we explained earlier.  

```matlab
receiptFiles = ds.Files(isReceipt);
montage(receiptFiles)
```

the isReceipt logical array plays the role of an index for the images that are receipts, stores them in receiptFiles, and displays them in montage format using the montage() function. 


