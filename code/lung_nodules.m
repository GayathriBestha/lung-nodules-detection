clc;
clear;
close all;

%% Step 1: Load the CT scan image
img = imread('lungimg1.png');  % Use the uploaded image
figure, imshow(img), title('Original CT Image');

%% Step 2: Convert to grayscale
if size(img, 3) == 3
    gray = rgb2gray(img);
else
    gray = img;
end
figure, imshow(gray), title('Grayscale Image');

%% Step 3: Preprocessing
filtered = medfilt2(gray);
enhanced = imadjust(filtered);
sharpened = imsharpen(enhanced);
figure, imshow(sharpened), title('Preprocessed Image');

%% Step 4: Lung Segmentation
bw = imbinarize(enhanced, 'adaptive', 'ForegroundPolarity','dark','Sensitivity',0.4);
bw = ~bw;  % Invert to make lungs white
bw = imfill(bw, 'holes');
bw = bwareaopen(bw, 500);
bw = imclose(bw, strel('disk', 5));
figure, imshow(bw), title('Segmented Lung Region');

%% Step 5: Mask the lungs on the original image
maskedImage = gray;
maskedImage(~bw) = 0;
figure, imshow(maskedImage), title('Masked Lung Image');

%% Step 6: Detect Nodules
% Threshold to extract brighter spots (potential nodules)
noduleThresh = imbinarize(maskedImage, 'adaptive', 'ForegroundPolarity','bright','Sensitivity',0.6);

noduleThresh = bwareaopen(noduleThresh, 30);
noduleThresh = imclose(noduleThresh, strel('disk', 2));
noduleThresh(~bw) = 0;  % Keep only within lung region

figure, imshow(noduleThresh), title('Potential Nodules Mask');

%% Step 7: Label Nodules and Show Rectangles
[labeledNodules, num] = bwlabel(noduleThresh);
stats = regionprops(labeledNodules, 'BoundingBox', 'Area');
% Filter and count nodules by size
validNod = [];
for k = 1:length(stats)
    if stats(k).Area > 20 && stats(k).Area < 1500
        validNod = [validNod; stats(k)];
    end
end

figure, imshow(gray), title('Detected Lung Nodules'); hold on;
for k = 1:length(validNod)
    rectangle('Position', validNod(k).BoundingBox, 'EdgeColor', 'r', 'LineWidth', 2);
    pos = validNod(k).BoundingBox;
    text(pos(1), pos(2)-10, sprintf('A=%.0f', validNod(k).Area), ...
        'Color', 'yellow', 'FontSize', 10);
end
hold off;

%% Step 8: Print Count
fprintf('Number of possible nodules detected: %d\n', length(validNod));
