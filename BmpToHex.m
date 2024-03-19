b=imread('testPic640_480.bmp'); % 24-bit BMP image RGB888 
c=rgb2gray(b); %RGB to Grayscale Image
k=1;
for i=1:1:480 % 2D image is written in a 1D array
for j=1:640
a(k)=c(i,j);
k=k+1;
end
end
fid = fopen('testPic.hex', 'wt'); % a hex file is generated
fprintf(fid, '%x\n', a); % 1D array is written in the hex file
disp('Text file write done');disp(' '); 
fclose(fid);
imshow(c); %image being displayed