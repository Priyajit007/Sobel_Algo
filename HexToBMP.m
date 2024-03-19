fid = fopen('testPicOut.hex', 'r'); %hex file is opened
hexdata =fscanf(fid, '%2x'); %data being retrived
fclose(fid);
B = reshape(hexdata,640,480); %1D array being reshaped to 2D array
C = transpose(B);
K= mat2gray(C); %Convert matrix to Grayscale Image
imshow(K);